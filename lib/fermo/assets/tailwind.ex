defmodule Fermo.Assets.Tailwind do
  if Application.spec(:tailwind) do
    @behaviour Fermo.Assets.Builder

    def build() do
      Tailwind.install_and_run(:default, [])
    end

    def output do
      ~w(app.css)
    end
  end
end
