defmodule VegaLite.Viewer do
  @moduledoc """
  Graphics rendering using Erlang's `:wx` bindings.

  This method if useful for viewing graphics in scripts
  and iex sessions.
  """

  @doc """
  Renders a `VegaLite` specification in GUI window widget.

  Requires Erlang compilation to include the `:wx` module.
  """
  @spec show(VegaLite.t()) :: :ok | :error
  def show(vl) do
    with {:ok, _pid} <- start_wx_viewer(vl), do: :ok
  end

  @doc """
  Same as `show/1`, but blocks until the window widget is closed.
  """
  @spec show_and_wait(VegaLite.t()) :: :ok | :error
  def show_and_wait(vl) do
    with {:ok, pid} <- start_wx_viewer(vl) do
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, _object, _reason} -> :ok
      end
    end
  end

  if Code.ensure_compiled(:wx) == {:module, :wx} do
    defp start_wx_viewer(vl) do
      vl
      |> VegaLite.Export.to_html()
      |> VegaLite.WxViewer.start()
    end
  else
    defp start_wx_viewer(_vl) do
      raise RuntimeError,
            "VegaLite.Viewer requires Erlang compilation to include the :wx module, but it's not available"
    end
  end
end
