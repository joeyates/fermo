In its default configuration, Fermo does not handle assets.

ESBuild can be activated using the module provided
(see below).

If you want to use another build system, just provide a
module which implements the `Fermo.Assets.Builder` behaviour.

# ESBuild

To activate ESBuild, add the following to `config/config.exs`:

```elixir
config :fermo, :assets, [Fermo.Assets.ESBuild, ...]

config :esbuild,
  version: "0.16.4",
  default: [
    args:
      ~w(priv/source/javascripts/application.js --bundle --target=es2017 --outdir=build/assets --external:/fonts/* --external:/images/*),
    env: %{"NODE_PATH" => Path.expand("deps", __DIR__)}
  ]
```

add the following to `config/dev.exs`:

```
Application.put_env(
  :fermo,
  :live_asset_pipelines,
  [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    ...
  ]
)
```

and add `:esbuild` to `mix.exs`:

```elixir

  defp application do
    [
      extra_applications: [:esbuild, ...]
    ]
  end

  defp deps do
    [
      {:esbuild, "~> 0.7.0"},
      ...
    ]
  end
```

This provides a standard ESBuild setup for development live mode
and for static production builds.
