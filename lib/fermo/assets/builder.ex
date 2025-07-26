defmodule Fermo.Assets.Builder do
  @callback build() :: {:ok}
  @doc """
  Returns a list of output file patterns that this builder generates.
  """
  @callback output() :: [Regex.t()]
end
