defmodule Fermo do
  @moduledoc """
  Fermo provides the main entry points for configuring a project
  """

  @build Application.compile_env(:fermo, :build, Fermo.Build)
  @pagination Application.compile_env(:fermo, :pagination, Fermo.Pagination)

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute(__MODULE__, :config, persist: true)
      @config unquote(opts)

      import I18n
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def initial_config() do
        Fermo.Config.initial(hd(__MODULE__.__info__(:attributes)[:config]))
      end
    end
  end

  @doc """
  Add a page to the configuration

  pages are the main way to add dynamic pages to Fermo.

  ## Examples

      page(
        config,
        "/templates/home.html.slim",
        "/index.html",
        %{id: "home", path: "/"}
      )
  """
  def page(config, template, filename, params \\ nil) do
    Fermo.Config.add_page!(config, template, filename, params)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    @pagination.paginate(config, template, options, context, fun)
  end

  def build(config) do
    @build.run(config)
  end
end
