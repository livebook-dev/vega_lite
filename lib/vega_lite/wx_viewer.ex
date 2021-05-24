if Code.ensure_compiled(:wx) == {:module, :wx} do
  defmodule VegaLite.WxViewer do
    @moduledoc false

    @behaviour :wx_object

    @title "VegaLite graphic"
    @size {1000, 800}

    @doc """
    Creates a graphical window displaying the given HTML.

    Returns `{:ok, pid}` on success, where `pid` identifies
    the process managing the window widget.
    """
    @spec start(binary()) :: {:ok, pid()} | :error
    def start(html) do
      case :wx_object.start(__MODULE__, [html: html], []) do
        {:error, _reason} -> :error
        {:wx_ref, _id, _obj, pid} -> {:ok, pid}
      end
    end

    @impl true
    def init(opts) do
      html = opts[:html]

      wx = :wx.new()

      frame = :wxFrame.new(wx, -1, @title, size: @size)
      :wxFrame.connect(frame, :close_window)

      web_view = :wxWebView.new(frame, -1)
      :wxWebView.setPage(web_view, html, "")

      :wxFrame.center(frame)
      :wxFrame.show(frame)

      {frame, :no_state}
    end

    @impl true
    def handle_event({:wx, _id, _obj, _data, {:wxClose, :close_window}}, state) do
      {:stop, :normal, state}
    end
  end
end
