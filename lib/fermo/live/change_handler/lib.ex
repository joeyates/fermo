defmodule Fermo.Live.ChangeHandler.Lib do
  @moduledoc """
  A change handler for library files in a Fermo project.

  When a library file changes, this module is notified by a `Fermo.Live.Watcher`
  and it triggers a recompilation of the Elixir code and reloads the live socket registry.
  """

  alias Fermo.Live.Dependencies

  require Logger

  @behaviour Fermo.Live.ChangeHandler

  @impl true
  def notify(_path) do
    Mix.Tasks.Compile.Elixir.run([])
    # Without running `mix compile`, the module disappears from disk. Not clear why
    System.shell("mix compile")
    Dependencies.reinitialize()
    Logger.debug("Forcing reload of all connected clients...")
    {:ok} = Fermo.Live.SocketRegistry.reload()
  end
end
