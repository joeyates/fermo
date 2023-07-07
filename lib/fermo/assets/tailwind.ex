defmodule Fermo.Assets.Tailwind do
  def build() do
    Tailwind.install_and_run(:default, [])
  end
end
