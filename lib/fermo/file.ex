defmodule Fermo.File do
  @callback copy(Pathname.t(), Pathname.t()) :: {:ok, [Pathname.t()]}
  def copy(source, destination) do
    path = Path.dirname(destination)
    ensure_path(path)
    {:ok, _files} = File.cp_r(source, destination)
  end

  @callback save(Pathname.t(), String.t()) :: :ok
  def save(pathname, body) do
    path = Path.dirname(pathname)
    ensure_path(path)
    File.write!(pathname, body, [:write])
  end

  def ensure_path(path) do
    File.mkdir_p!(path)
  end
end
