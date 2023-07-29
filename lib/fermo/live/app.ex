defmodule Fermo.Live.App do
  @moduledoc false

  use Application

  alias Fermo.Live.{
    AssetPipeline,
    Dependencies,
    LibChangeHandler,
    Server,
    Socket,
    SocketRegistry,
    TemplateChangeHandler,
    Watcher
  }

  @assets Application.compile_env(:fermo, :assets, [])
  @code_watchers [
    [dir: "lib", notify: LibChangeHandler],
    [dir: "priv/source", notify: TemplateChangeHandler],
  ]

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

    children =
      live_mode_servers() ++
      [
        cowboy,
        {Dependencies, [app_module: app_module]},
        {SocketRegistry, []}
      ] ++
      live_watchers() ++
      live_asset_pipelines()

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

  defp live_asset_pipelines() do
    Application.get_env(:fermo, :live_asset_pipelines, [])
    |> Enum.map(&{AssetPipeline, &1})
  end

  defp live_watchers do
    (@code_watchers ++ asset_watchers())
    |> Enum.map(&{Watcher, &1})
  end

  defp asset_watchers do
    if Enum.any?(@assets) do
      matches =
        @assets
        |> Enum.flat_map(&(&1.output))
        |> Enum.map(&Regex.escape/1)
        |> Enum.join("|")
      wanted = Regex.compile!("(#{matches})$")
      [
        [
          dir: "build",
          wanted: wanted,
          call: [
            {Fermo.Assets, :create_manifest, []},
            {Fermo.Live.SocketRegistry, :reload, []}
          ]
        ]
      ]
    else
      []
    end
  end

  # Allow projects to add children
  defp live_mode_servers() do
    Application.get_env(:fermo, :live_mode_servers, [])
  end
end
