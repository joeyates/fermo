defmodule Fermo.Live.App do
  @moduledoc false

  use Application

  alias Fermo.Live.{
    ChangeHandler,
    Dependencies,
    Server,
    Socket,
    SocketRegistry,
    Watcher
  }

  def start(_type, _args) do
    Application.ensure_all_started(:telemetry)
    Application.ensure_all_started(:cowboy)

    cowboy = {
      Plug.Cowboy,
      scheme: :http,
      plug: Server,
      options: [dispatch: dispatch(), port: port()]
    }

    app_module = Mix.Fermo.Module.module!()

    children = live_mode_servers() ++ [
      cowboy,
      {Watcher, dirs: ["lib", "priv/source"]},
      {ChangeHandler, []},
      {Dependencies, [app_module: app_module]},
      {SocketRegistry, []}
    ] ++ live_mode_assets()

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid}
  end

  def stop(_state) do
    Application.stop(:cowboy)
    Application.stop(:telemetry)
  end

  def port do
    String.to_integer(System.get_env("PORT") || "4001")
  end

  defp dispatch() do
    [
      {
        :_,
        [
          {"/__fermo/ws/[...]", Socket, [name: :fermo_live_socket]},
          {:_, Plug.Cowboy.Handler, {Server, Server.init([])}}
        ]
      }
    ]
  end

  defp live_mode_assets() do
    case Application.fetch_env(:fermo, :live_mode_assets) do
      :error -> []
      {:ok, spec} -> spec
    end
  end

  # Allow projects to add children
  defp live_mode_servers() do
    case Application.fetch_env(:fermo, :live_mode_servers) do
      :error -> []
      {:ok, servers} -> servers
    end
  end
end
