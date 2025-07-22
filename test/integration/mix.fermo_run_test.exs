defmodule Mix.FermoRunTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup_all do
    root = File.cwd!()
    test_path = Path.join([root, "test", "integration", "test_project"])

    File.cd!(test_path, fn ->
      env = [
        {"BASE_URL", "http://localhost:4001"},
        {"BUILD_ENV", "development"},
        {"MIX_ENV", "dev"}
      ]

      {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      {_deps_output, 0} = System.cmd("mix", ["deps.get"], env: env, stderr_to_stdout: true)
      {_compile_output, 0} = System.cmd("mix", ["compile"], env: env, stderr_to_stdout: true)
      {_build_output, 0} = System.cmd("mix", ["fermo.build"], env: env, stderr_to_stdout: true)
    end)

    build_path = Path.join(test_path, "build")

    on_exit(fn ->
      File.cd!(test_path, fn ->
        {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      end)
    end)

    %{build_path: build_path}
  end

  test "it builds dynamic pages", context do
    context.build_path |> Path.join("index.html") |> File.regular?() |> assert()
  end

  test "it builds simple pages", context do
    context.build_path |> Path.join("simple/index.html") |> File.regular?() |> assert()
  end

  test "it builds localized pages", context do
    context.build_path |> Path.join("local/index.html") |> File.regular?() |> assert()
    context.build_path |> Path.join("it/local/index.html") |> File.regular?() |> assert()
  end

  test "it builds pagination", context do
    context.build_path |> Path.join("foos/index.html") |> File.regular?() |> assert()
    context.build_path |> Path.join("foos/pages/2.html") |> File.regular?() |> assert()
  end

  test "it builds assets", context do
    context.build_path |> Path.join("manifest.json") |> File.regular?() |> assert()
  end

  test "it builds the sitemap", context do
    context.build_path |> Path.join("sitemap.xml") |> File.regular?() |> assert()
  end
end
