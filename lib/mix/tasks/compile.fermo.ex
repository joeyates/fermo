defmodule Mix.Tasks.Compile.Fermo do
  use Mix.Task

  @moduledoc """
  Compile EEx and Slime templates
  """
  def run(_args) do
    Mix.Fermo.Compiler.run()
  end
end
