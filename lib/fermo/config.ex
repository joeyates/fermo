defmodule Fermo.Config do
  @moduledoc false

  @i18n Application.compile_env(:fermo, :i18n, Fermo.I18n)
  @localizable Application.compile_env(:fermo, :localizable, Fermo.Localizable)
  @simple Application.compile_env(:fermo, :simple, Fermo.Simple)
  @template Application.compile_env(:fermo, :template, Fermo.Template)

  def initial(config) do
    build_path = config[:build_path] || "build"
    pages = config[:pages] || []
    statics = config[:statics] || []

    config
    |> put_in([:build_path], build_path)
    |> put_in([:pages], pages)
    |> put_in([:statics], statics)
    |> @localizable.add()
    |> @simple.add()
    |> put_in([:stats], %{})
    |> put_in([:stats, :start], Time.utc_now)
  end

  @callback post_config(map()) :: map()
  def post_config(config) do
    pages = Enum.map(
      config.pages,
      fn page ->
        page
        |> set_path(config)
        |> merge_defaults(config)
      end
    )

    config
    |> put_in([:pages], pages)
    |> @i18n.optionally_build_path_map()
    |> put_in([:stats, :post_config_completed], Time.utc_now)
  end

  def add_page(config, template, filename, params \\ %{}) do
    if Fermo.Paths.source_file_exists?(template) do
      pages = Map.get(config, :pages, [])
      page = page_from(template, filename, params)
      config = put_in(config, [:pages], pages ++ [page])
      {:ok, config}
    else
      {:error, "Template not found: #{template}"}
    end
  end

  def add_page!(config, template, filename, params \\ %{}) do
    {:ok, config} = add_page(config, template, filename, params)
    config
  end

  @doc """
  Indicate that a file should be simply copied to the build,
  without any transformation.

  You can also add statics via the `:statics` attribute in `config`.
  """
  def add_static(config, source, filename) do
    statics = Map.get(config, :statics)
    put_in(config, [:statics], statics ++ [%{source: source, filename: filename}])
  end

  def page_from(template, filename, params) do
    %{
      template: template,
      filename: filename,
      params: params
    }
  end

  defp set_path(page, config) do
    %{template: template, filename: supplied_filename} = page
    module = @template.module_for_template(template)
    context = @template.build_context(module, template, page)
    params = @template.params_for(module, page)
    path_override = @template.content_for(module, [:path, params, context])
    is_html = String.match?(template, ~r(\.html.\w+))
    # This depends on the default content_for returning "" and not nil
    {filename, path} = if path_override == "" do
      {
        Fermo.Paths.path_to_filename(supplied_filename, as_index_html: is_html),
        Fermo.Paths.filename_to_path(supplied_filename, as_index_html: is_html)
      }
    else
      {
        Fermo.Paths.path_to_filename(path_override, as_index_html: is_html),
        # Avoid extra whitespace introduced by templating
        String.replace(path_override, ~r/\n/, "")
      }
    end

    pathname = Path.join(config.build_path, filename)

    page
    |> put_in([:filename], filename)
    |> put_in([:path], path)
    |> put_in([:pathname], pathname)
  end

  defp optionally_add_extensions(nil), do: nil
  defp optionally_add_extensions(layout), do: "#{layout}.html.slim"

  defp merge_defaults(page, config) do
    template = page.template
    module = @template.module_for_template(template)
    defaults = @template.defaults_for(module)

    layout = cond do
      Map.has_key?(page.params, :layout) ->
        optionally_add_extensions(page.params.layout)
      Map.has_key?(defaults, :layout) ->
        optionally_add_extensions(defaults.layout)
      Map.has_key?(config, :layout) ->
        optionally_add_extensions(config.layout)
      true ->
        "layouts/layout.html.slim"
    end

    params =
      defaults
      |> Map.merge(page[:params] || %{})
      |> put_in([:module], module)
      |> put_in([:layout], layout)

    put_in(page, [:params], params)
  end
end
