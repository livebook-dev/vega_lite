# TODO: remove on v1.0
defmodule VegaLite.Viewer do
  @moduledoc false

  @deprecated "Use VegaLite.Convert.open_viewer/1 in from the :vega_lite_convert package instead"
  @spec show(VegaLite.t()) :: :ok | :error
  def show(vl) do
    with {:ok, _pid} <- start_wx_viewer(vl), do: :ok
  end

  @deprecated "Use VegaLite.Convert.open_viewer_and_wait/1 in from the :vega_lite_convert package instead"
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
    |> VegaLite.Export.to_html_no_deprecation()
    |> VegaLite.WxViewer.start()
  end
end
