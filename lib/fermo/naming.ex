defmodule Fermo.Naming do
  def source_path_to_module("/" <> path) do
    source_path_to_module(path)
  end

  def source_path_to_module(path) do
    base =
      path
      |> String.replace(~r/\.html\.\w+/, "")
      |> String.replace("/", ".")
    upper = Regex.replace(~r/(?:\b|\.)([a-z])/, base, &(String.upcase(&1)))
    camel = Regex.replace(~r/_([a-z])/, upper, fn _, t -> String.upcase(t) end)
    :"Elixir.Fermo.Template.#{camel}"
  end
end
