defmodule Fermo.App do
  @moduledoc false

  use Application

  require Logger

  def start(_start_type, _args \\ []) do
    Logger.info "Starting Fermo.App"
    children = [{I18n, []}, {Fermo.Assets, %{}}]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid}
  end
end
