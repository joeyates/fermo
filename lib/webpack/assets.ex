defmodule Webpack.Assets do
  @moduledoc """
  Handles an external (Webpack) pipeline.

  Runs the pipeline, then loads the manifest it produces into a GenServer
  in order to provide asset name mapping.
  """

  @webpack_config_path_default "webpack.config.js"

  def build() do
    if File.exists?(webpack_config_path()) do
      System.cmd("yarn", ["run", "webpack"]) |> handle_build_result()
    else
      {:ok}
    end
  end

  def load_manifest() do
    manifest = "build/manifest.json"
    |> File.read!
    |> Jason.decode!
    |> Enum.into(
      # Ensure asset names have no initial '/', while
      # asset paths do
      %{},
      fn
        {"/" <> k, "/" <> v} -> {k, "/" <> v}
        {"/" <> k,        v} -> {k, "/" <> v}
        {       k, "/" <> v} -> {k, "/" <> v}
        {       k,        v} -> {k, "/" <> v}
      end
    )
    GenServer.call(:assets, {:put, manifest})
    {:ok}
  end

  def webpack_config_path do
    Application.get_env(
      :fermo,
      :webpack_config_path,
      @webpack_config_path_default
    )
  end

  defp handle_build_result({_output, 0}) do
    load_manifest()
  end
  defp handle_build_result({output, _exit_status}) do
    {:error, "External webpack pipeline failed to build\n\n#{output}"}
  end
end
