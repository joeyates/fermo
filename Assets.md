In its default configuration, Fermo does not handle assets.

ESBuild and Webpack can be activated using the modules provided
(see below).

If you want to use another build system, just provide a
module which implements the `Fermo.Assets` behaviour.

# ESBuild

To activate ESBuild, add the following to `config/config.exs`:

```elixir
config :fermo, :assets, Assets.ESBuild

config :esbuild,
  version: "0.16.4",
  default: [
    args:
      ~w(priv/source/javascripts/application.js --bundle --target=es2017 --outdir=build --external:/fonts/* --external:/images/*),
    env: %{"NODE_PATH" => Path.expand("deps", __DIR__)}
  ]
  ...
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

# Webpack

TODO
