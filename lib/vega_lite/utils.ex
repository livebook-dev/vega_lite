defmodule VegaLite.Utils do
  @moduledoc false

  @doc """
  Generates a string unique across processes and time.
  """
  @spec process_timestamp() :: binary()
  def process_timestamp() do
    "#{:erlang.phash2({node(), self()})}-#{System.os_time()}"
  end
end
