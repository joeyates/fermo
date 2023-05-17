defmodule Assets.ESBuild do
  def build() do
    # Unless there is an override, run standard ESBuild
    Esbuild.install_and_run(:default, [])
  end
end
