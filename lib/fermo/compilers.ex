defmodule Fermo.Compilers do
  @compilers_slim Application.compile_env(:fermo, :compilers_slim, Fermo.Compilers.Slim)
  @mix_utils Application.compile_env(:fermo, :mix_utils, Mix.Utils)

  @default_compilers [
    eex: Fermo.Compilers.EEx,
    slim: @compilers_slim
  ]

  @callback compilers() :: [Keyword.t()]
  def compilers() do
    @default_compilers
  end

  def template_extensions() do
    Keyword.keys(compilers())
  end

  @callback templates(Pathname.t()) :: [{atom(), Pathname.t()}]
  def templates(source_path) do
    Enum.flat_map(
      template_extensions(),
      fn extension ->
        files =
          @mix_utils.extract_files([source_path], [extension])
          |> MapSet.new()
          |> MapSet.to_list()

        Enum.map(files, &{extension, &1})
      end
    )
  end
end
