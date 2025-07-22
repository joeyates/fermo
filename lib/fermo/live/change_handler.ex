defmodule Fermo.Live.ChangeHandler do
  @moduledoc """
  A behaviour for handling live changes in a Fermo project.
  """

  @callback notify(String.t()) :: nil
end
