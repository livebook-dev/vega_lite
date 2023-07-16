defmodule VegaLite.Viewer do
  @moduledoc """
  Graphics rendering using Erlang's `:wx` bindings.

  This method is useful for viewing graphics in scripts
  and IEx sessions. Note it requires Erlang/OTP 24+ with
  a recent WxWidgets installation with webview support.
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

  defp start_wx_viewer(vl) do
    vl
    |> VegaLite.Export.to_html()
    |> VegaLite.WxViewer.start()
  end
end
