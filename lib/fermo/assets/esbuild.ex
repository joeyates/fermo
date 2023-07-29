defmodule Fermo.Assets.ESBuild do
  @behaviour Fermo.Assets.Builder

  def build() do
    # Unless there is an override, run standard ESBuild
    Esbuild.install_and_run(:default, [])
    {:ok}
  end

  def output do
    ~w(application.js)
  end
end
