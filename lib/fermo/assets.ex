defmodule Fermo.Assets do
  @moduledoc """
  Loads the asset manifest and provides helpers to build
  paths to the assets.
  """

  use GenServer

  @asset_path Application.compile_env(
                :fermo,
                :asset_path,
                "build"
              )
  @asset_extensions Application.compile_env(
                      :fermo,
                      :asset_extensions,
                      ~w(.css .ico .jpg .jpeg .js .png .txt)
                    )
  @digested_filename ~r(-[a-z0-9]{32}\.[a-z0-9]+$)
  @live_asset_base Application.compile_env(
                     :fermo,
                     :live_asset_base,
                     "/"
                   )
  def start_link(args \\ %{}) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    {:ok, args}
  end

  def create_manifest() do
    with {:ok, files} <- list_files(),
         {:ok, metadata} <- build_metadata(files),
         {:ok} <- copy_new_digested(metadata),
         {:ok, manifest} <- to_manifest(metadata) do
      GenServer.call(__MODULE__, {:put, manifest})
      {:ok}
    else
      {:error, reason} ->
        raise reason
    end
  end

  defp list_files do
    files =
      @asset_path
      |> Path.join("**")
      |> Path.wildcard()
      |> Enum.filter(&is_asset?/1)

    {:ok, files}
  end

  defp is_asset?(path) do
    with false <- File.dir?(path),
         filename = Path.basename(path),
         false <- Regex.match?(@digested_filename, filename),
         extension = Path.extname(path),
         true <- extension in @asset_extensions do
      true
    else
      _ -> false
    end
  end

  defp build_metadata(files) do
    files
    |> Enum.map(fn file ->
      relative_filename = Path.relative_to(file, @asset_path)
      content = File.read!(file)
      digest = content |> :erlang.md5() |> Base.encode16(case: :lower)
      extension = Path.extname(file)
      root = Path.rootname(file, extension)
      digested_filename = "#{root}-#{digest}#{extension}"
      relative_digested_filename = Path.relative_to(digested_filename, @asset_path)

      %{
        filename: file,
        relative_filename: relative_filename,
        digest: digest,
        digested_filename: digested_filename,
        asset_path: "/#{relative_digested_filename}",
        extension: extension
      }
    end)
    |> then(&{:ok, &1})
  end

  defp copy_new_digested(metadata) do
    metadata
    |> Enum.filter(&(!File.regular?(&1.digested_filename)))
    |> Enum.each(fn item ->
      File.cp!(item.filename, item.digested_filename)
    end)

    {:ok}
  end

  defp to_manifest(metadata) do
    manifest =
      metadata
      |> Enum.map(fn item ->
        {item.relative_filename, item}
      end)
      |> Enum.into(%{})

    {:ok, manifest}
  end

  def manifest do
    GenServer.call(__MODULE__, {:manifest})
  end

  def path("/" <> name) do
    GenServer.call(__MODULE__, {:path, name})
  end

  def path(name) do
    GenServer.call(__MODULE__, {:path, name})
  end

  def path!(name) do
    {:ok, path} = path(name)
    path
  end

  @impl true
  def handle_call({:put, state}, _from, _state) do
    {:reply, {:ok}, state}
  end

  def handle_call({:manifest}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:path, name}, _from, state) do
    if Map.has_key?(state, name) do
      item = state[name]
      {:reply, {:ok, item.asset_path}, state}
    else
      {:reply, {:error, "'#{name}' not found in manifest"}, state}
    end
  end

  defmacro asset_path(name) do
    quote do
      context = var!(context)

      if context[:page][:live] do
        live_asset_path(unquote(name))
      else
        static_asset_path(unquote(name))
      end
    end
  end

  def static_asset_path("https://" <> _path = url) do
    url
  end

  def static_asset_path(filename) do
    path!(filename)
  end

  def live_asset_path(filename) do
    manifest_path = path!(filename)
    Path.join(@live_asset_base, manifest_path)
  end

  # TODO: make this a context aware macro
  def font_path("https://" <> _path = url) do
    url
  end

  def font_path(filename) do
    path!("/fonts/#{filename}")
  end

  defmacro image_path("https://" <> _path = url) do
    quote do
      static_image_path(unquote(url))
    end
  end

  defmacro image_path(name) do
    quote do
      context = var!(context)

      if context[:page][:live] do
        live_image_path(unquote(name))
      else
        static_image_path(unquote(name))
      end
    end
  end

  defmacro image_tag(filename, attributes) do
    quote do
      if String.starts_with?(unquote(filename), "https://") do
        image_tag_with_attributes(unquote(filename), unquote(attributes))
      else
        context = var!(context)

        url =
          if context[:page][:live] do
            live_image_path(unquote(filename))
          else
            static_image_path(unquote(filename))
          end

        image_tag_with_attributes(url, unquote(attributes))
      end
    end
  end

  def image_tag_with_attributes(url, attributes) do
    attribs =
      Enum.map(attributes, fn {k, v} ->
        "#{k}=\"#{v}\""
      end)

    "<img src=\"#{url}\" #{Enum.join(attribs, " ")}/>"
  end

  def static_image_path("https://" <> _path = url) do
    url
  end

  def static_image_path("/" <> filename) do
    path!("/images/#{filename}")
  end

  def static_image_path(filename) do
    path!("/images/#{filename}")
  end

  def live_image_path(filename) do
    live_asset_path("images/#{filename}")
  end

  defmacro javascript_path(name) do
    quote do
      context = var!(context)

      if context[:page][:live] do
        live_javascript_path(unquote(name))
      else
        static_javascript_path(unquote(name))
      end
    end
  end

  # TODO: handle user-supplied attributes, e.g. defer="true"
  defmacro javascript_include_tag(name) do
    quote do
      context = var!(context)

      url =
        if context[:page][:live] do
          live_javascript_path(unquote(name))
        else
          static_javascript_path(unquote(name))
        end

      "<script src=\"#{url}\" type=\"text/javascript\"></script>"
    end
  end

  def static_javascript_path("https://" <> _path = url) do
    url
  end

  def static_javascript_path(name) do
    path!("/#{name}.js")
  end

  def live_javascript_path(name) do
    live_asset_path("/#{name}.js")
  end

  defmacro stylesheet_path(name) do
    quote do
      context = var!(context)

      if context[:page][:live] do
        live_stylesheet_path(unquote(name))
      else
        static_stylesheet_path(unquote(name))
      end
    end
  end

  defmacro stylesheet_link_tag(name) do
    quote do
      context = var!(context)

      url =
        if context[:page][:live] do
          live_stylesheet_path(unquote(name))
        else
          static_stylesheet_path(unquote(name))
        end

      "<link href=\"#{url}\" media=\"all\" rel=\"stylesheet\" />"
    end
  end

  def static_stylesheet_path("https://" <> _path = url) do
    url
  end

  def static_stylesheet_path(name) do
    path!("/#{name}.css")
  end

  def live_stylesheet_path(name) do
    live_asset_path("/#{name}.css")
  end
end
