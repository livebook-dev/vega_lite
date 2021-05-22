defmodule VegaLite.Export do
  @moduledoc """
  Various export methods for a `VegaLite` specification.
  """

  alias VegaLite.Utils

  @doc """
  Saves a `VegaLite` specification to file in one of
  the supported formats.

  ## Options

    * `:format` - the format to export the graphic as,
      must be either of: `:json`, `:html`. By default
      the format is inferred from the file extension.
  """
  @spec save!(VegaLite.t(), binary(), keyword()) :: :ok
  def save!(vl, path, opts \\ []) do
    format =
      Keyword.get_lazy(opts, :format, fn ->
        path |> Path.extname() |> String.trim_leading(".") |> String.to_existing_atom()
      end)

    content =
      case format do
        :json ->
          to_json(vl)

        :html ->
          to_html(vl)

        _ ->
          raise ArgumentError,
                "unsupported export format, expected :json or :html, got: #{inspect(format)}"
      end

    File.write!(path, content)
  end

  @doc """
  Returns the underlying Vega-Lite specification as JSON.
  """
  @spec to_json(VegaLite.t()) :: String.t()
  def to_json(vl) do
    Utils.assert_jason!("to_json/1")

    vl
    |> VegaLite.to_spec()
    |> Jason.encode!()
  end

  @doc """
  Builds an HTML page that renders the given graphic.

  The HTML page loads necessary JavaScript dependencies from a CDN
  and then renders the graphic in a root element.
  """
  @spec to_html(VegaLite.t()) :: binary()
  def to_html(vl) do
    json = to_json(vl)

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Vega-Lite graphic</title>
      <script src="https://cdn.jsdelivr.net/npm/vega@5.20.2"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.1.0"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.17.0"></script>
    </head>
    <body>
      <div id="graphic"></div>
      <script type="text/javascript">
        var spec = JSON.parse("#{escape_double_quotes(json)}");
        vegaEmbed("#graphic", spec);
      </script>
    </body>
    </html>
    """
  end

  defp escape_double_quotes(json) do
    String.replace(json, ~s{"}, ~s{\\"})
  end
end
