defmodule Fermo.Assets.ESBuild do
  if Application.spec(:esbuild) do
    require Esbuild
    @behaviour Fermo.Assets.Builder

    def build() do
      # Unless there is an override, run standard ESBuild
      Esbuild.install_and_run(:default, [])
      {:ok}
    end

    def output() do
      [~r{application(-\w+)?\.js}]
    end
  end
end
