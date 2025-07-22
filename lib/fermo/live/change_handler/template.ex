defmodule Fermo.Live.ChangeHandler.Template do
  @moduledoc """
  A change handler for template files in a Fermo project.

  When a template file changes, this module is notified by
  a `Fermo.Live.Watcher` and it triggers a recompilation of the templates.
  """

  @behaviour Fermo.Live.ChangeHandler

  alias Fermo.Live.{Dependencies, SocketRegistry}
  alias Mix.Fermo.{Compiler, Paths}

  @impl true
  def notify(path) do
    recompile_templates()
    app_relative_path = Paths.app_relative_path(path)
    template_relative_path(app_relative_path)
    |> notify_template_change()
  end

  defp recompile_templates() do
    :ok = Compiler.run()
  end

  defp template_relative_path(path) do
    root = "priv/source/"
    if String.starts_with?(path, root) do
      root_length = byte_size(root)
      <<_::binary-size(root_length), rest::binary>> = path
      rest
    else
      nil
    end
  end

  defp notify_template_change(relative_path) do
    {:ok, pages} = Dependencies.pages_by_dependency(relative_path)
    Enum.each(pages, fn page ->
      {:ok} = SocketRegistry.reload(page.path)
    end)
  end
end
