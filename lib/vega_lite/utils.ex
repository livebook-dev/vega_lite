defmodule VegaLite.Utils do
  @moduledoc false

  @doc """
  Ensures `Jason` is available and raises an error otherwise.
  """
  def assert_jason!(fn_name) do
    unless Code.ensure_loaded?(Jason) do
      raise RuntimeError, """
      #{fn_name} depends on the Jason package.

      You can install it by adding

          {:jason, "~> 1.2"}

      to your dependency list.
      """
    end
  end
end
