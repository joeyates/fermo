defmodule Fermo.Live.LibChangeHandler do
  @moduledoc false

  def notify(_path) do
    Mix.Tasks.Compile.Elixir.run([])
    recompile_templates()
    notify_lib_change()
  end

  defp recompile_templates() do
    :ok = Mix.Fermo.Compiler.run()
  end

  defp notify_lib_change() do
    {:ok} = Fermo.Live.SocketRegistry.reload()
  end
end
