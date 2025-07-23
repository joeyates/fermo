defmodule Fermo.Live.ChangeHandler.Template do
  @moduledoc """
  A change handler for template files in a Fermo project.

  When a template file changes, this module is notified by
  a `Fermo.Live.Watcher` and it triggers a recompilation of the templates.
  """

  @behaviour Fermo.Live.ChangeHandler

  alias Fermo.Live.{Dependencies, SocketRegistry}
  alias Mix.Fermo.{Compiler, Paths}

  require Logger

  @impl true
  def notify(path) do
    app_relative_path =
      path
      |> Paths.app_relative_path()
      |> template_relative_path()

    recompile(app_relative_path)
  end

  defp recompile(template_path) do
    Logger.debug("#{__MODULE__} - Recompiling template: #{template_path}")
    recompile_updated()
    notify_template_change(template_path)
  end

  defp recompile_updated() do
    :ok = Compiler.run()
  end

  defp template_relative_path(path) do
    root = "priv/source/"

    if String.starts_with?(path, root) do
      root_length = byte_size(root)
      <<_::binary-size(root_length)>> <> rest = path
      rest
    end
  end

  defp notify_template_change(relative_path) do
    {:ok, pages} = Dependencies.pages_by_dependency(relative_path)

    Enum.each(pages, fn page ->
      {:ok} = SocketRegistry.reload(page.path)
    end)
  end
end
