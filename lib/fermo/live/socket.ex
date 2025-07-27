defmodule Fermo.Live.Socket do
  @behaviour :cowboy_websocket

  alias Fermo.Live.Dependencies
  alias Fermo.Live.SocketRegistry

  require Logger

  def init(request, _state) do
    {:cowboy_websocket, request, []}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_info({:reload}, state) do
    Logger.debug("#{__MODULE__} Sending reload message to client")
    {:reply, {:text, "reload"}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def websocket_handle({:text, "subscribe:live-reload:" <> path}, state) do
    uri = URI.new!(path)
    %{"generation" => client_generation} = URI.decode_query(uri.query)
    {:ok, generation} = Dependencies.generation()

    if generation == client_generation do
      Fermo.Live.SocketRegistry.subscribe(uri.path, self())

      {:reply, {:text, "fermo:live-reload subscribed for '#{path}'"}, state}
    else
      Logger.debug(
        "#{__MODULE__} Client generation #{client_generation} does not match server generation #{generation} - sending reload message"
      )

      {:reply, {:text, "reload"}, state}
    end
  end

  def websocket_handle({:text, "rebuild:" <> path}, state) do
    Logger.debug("#{__MODULE__} Handling rebuild request, path: #{path}")

    response =
      case Fermo.Live.Dependencies.page_from_path(path) do
        {:ok, page} ->
          # TODO: It's very heavy-handed to reload the *whole* configuration
          #   It would be better to have a method to reload just one page
          {:ok} = Dependencies.reinitialize()
          {:ok} = SocketRegistry.reload(page.path)
          "Initiated rebuild of '#{path}'"

        {:error, :not_found} ->
          Logger.error("#{__MODULE__} - Page not found for rebuild request, path: #{path}")
          "Page not found for path: #{path}"
      end

    {:reply, {:text, response}, state}
  end

  def websocket_handle(_info, state) do
    {:ok, state}
  end
end
