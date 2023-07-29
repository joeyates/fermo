defmodule Fermo.Assets.Builder do
  @callback build() :: {:ok}
  @callback output() :: [String.t()]
end
