defmodule Fermo.Live.Watcher do
  @moduledoc false

  use GenServer

  require Logger

  def child_spec(args) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [args]},
      restart: :transient
    }
  end

  def start_link(opts) do
    directory = opts[:dir] || raise "Directory option :dir is required for Fermo.Live.Watcher"

    if !File.dir?(directory) do
      Logger.warning("Directory '#{directory}' does not exist, creating it for live reload")
      File.mkdir_p!(directory)
    end

    start_opts = [dirs: [directory]]

    case FileSystem.start_link(start_opts) do
      {:ok, pid} ->
        opts =
          opts
          |> Enum.into(%{})
          |> Map.put(:pid, pid)

        GenServer.start_link(__MODULE__, opts)

      other ->
        Logger.warning("Failed to start file watcher for live reload")
        {:error, other}
    end
  end

  @impl true
  def init(%{} = opts) do
    Logger.debug("Fermo.Live.Watcher starting with options: #{inspect(opts)}")
    FileSystem.subscribe(opts.pid)
    {:ok, opts}
  end

  @impl true
  def handle_info({:file_event, _pid, {path, events}}, state) do
    with true <- is_ready?(events),
         true <- wanted?(path, state),
         true <- File.regular?(path) do
      dispatch(path, state)
    end

    {:noreply, state}
  end

  defp dispatch(path, state) do
    dispatch_call(path, state)
    dispatch_notify(path, state)
  end

  def dispatch_call(path, %{call: calls} = state) when is_list(calls) do
    calls
    |> Enum.each(fn call ->
      state = Map.put(state, :call, call)
      apply(__MODULE__, :dispatch_call, [path, state])
    end)
  end

  def dispatch_call(_path, %{call: {m, f, a}}) do
    Logger.debug("Fermo.Live.Watcher calling #{m}.#{f}(#{inspect(a)})")
    apply(m, f, a)
  end

  def dispatch_call(_path, _state), do: {:ok}

  def dispatch_notify(path, %{notify: modules} = state) when is_list(modules) do
    modules
    |> Enum.each(fn module ->
      state = Map.put(state, :notify, module)
      apply(__MODULE__, :dispatch_notify, [path, state])
    end)
  end

  def dispatch_notify(path, %{notify: module}) do
    Logger.debug("Fermo.Live.Watcher notifying #{module} of change to file '#{path}'")
    apply(module, :notify, [path])
  end

  def dispatch_notify(_path, _state), do: {:ok}

  defp is_ready?(events) do
    :modified in events && :closed in events
  end

  defp wanted?(path, %{wanted: wanted}) when is_list(wanted) do
    Logger.debug("Checking if path matches any wanted patterns: #{path}, #{inspect(wanted)}")
    wanted = Enum.any?(wanted, &String.match?(path, &1))

    if wanted do
      Logger.debug("Path '#{path}' matches one of the wanted patterns.")
    end

    wanted
  end

  defp wanted?(path, %{wanted: wanted}) do
    Logger.debug("Checking if path matches wanted pattern: #{path}, #{inspect(wanted)}")
    String.match?(path, wanted)
  end

  defp wanted?(_path, _state) do
    Logger.debug("No 'wanted' pattern specified, assuming all paths are wanted.")
    true
  end
end
