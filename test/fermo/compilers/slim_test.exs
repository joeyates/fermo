if !function_exported?(:"Elixir.Helpers", :__info__, 1) do
  defmodule Helpers do
    defmacro __using__(_opts \\ %{}) do
    end
  end
end

defmodule Fermo.Compilers.SlimTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  setup do
    stub(FileMock, :write!, fn _, _, _ -> :ok end)
    stub(FileMock, :read!, fn _ -> "foo" end)

    :ok
  end

  test "it compiles files" do
    expect(FileMock, :write!, fn filename, _content, _options ->
      filename
      |> String.ends_with?("lib/fermo/ebin/Elixir.Fermo.Template.Path.To.Template.beam")
      |> assert()
    end)

    Fermo.Compilers.Slim.compile("path/to/template")
  end
end
