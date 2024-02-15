defmodule FileBehaviour do
  @callback read(Path.t()) :: {:ok, String.t()}
  @callback read!(Path.t()) :: String.t()
  @callback stream!(Path.t(), [atom()]) :: File.Stream.t()
  @callback write!(Path.t(), String.t()) :: :ok
  @callback write!(Path.t(), String.t(), [atom()]) :: :ok
  @callback exists?(Path.t()) :: boolean()
end
