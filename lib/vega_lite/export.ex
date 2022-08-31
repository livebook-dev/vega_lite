defmodule VegaLite.Export do
  @moduledoc """
  Various export methods for a `VegaLite` specification.

  All of the export functions depend on the `:jason` package.
  Additionally the PNG, SVG and PDF exports rely on npm packages,
  so you will need Node.js, `npm`, and the following dependencies:

      npm install -g vega vega-lite canvas
      # or in the current directory
      npm install vega vega-lite canvas
  """

  alias VegaLite.Utils

  @doc """
  Saves a `VegaLite` specification to file in one of
  the supported formats.

  ## Options

    * `:format` - the format to export the graphic as,
      must be either of: `:json`, `:html`, `:png`, `:svg`, `:pdf`.
      By default the format is inferred from the file extension.
    * `:local_npm_prefix` - used for `:png`, `:svg`, `:pdf` formats to help locate local npm directory.
      For example in Phoenix projects you need to pass `local_npm_prefix: "assets"`.
  """
  @spec save!(VegaLite.t(), binary(), keyword()) :: :ok
  def save!(vl, path, opts \\ []) do
    {format, opts} =
      Keyword.pop_lazy(opts, :format, fn ->
        path |> Path.extname() |> String.trim_leading(".") |> String.to_existing_atom()
      end)

    content =
      case format do
        :json ->
          to_json(vl)

        :html ->
          to_html(vl)

        :png ->
          to_png(vl, opts)

        :svg ->
          to_svg(vl, opts)

        :pdf ->
          to_pdf(vl, opts)

        _ ->
          raise ArgumentError,
                "unsupported export format, expected :json, :html, :png, :svg or :pdf, got: #{inspect(format)}"
      end

    File.write!(path, content)
  end

  @compile {:no_warn_undefined, {Jason, :encode!, 1}}

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
      <script src="https://cdn.jsdelivr.net/npm/vega@5.21.0"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.2.0"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.20.5"></script>
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

  @doc """
  Renders the given graphic as a PNG image and returns
  its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - used for `:png`, `:svg`, `:pdf` formats to help locate local npm directory.
    For example in Phoenix projects you need to pass `local_npm_prefix: "assets"`.
  """
  @spec to_png(VegaLite.t()) :: binary()
  def to_png(vl, opts \\ []) do
    node_convert(vl, "png", "to_png/1", opts)
  end

  @doc """
  Renders the given graphic as an SVG image and returns
  its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - used for `:png`, `:svg`, `:pdf` formats to help locate local npm directory.
    For example in Phoenix projects you need to pass `local_npm_prefix: "assets"`.
  """
  @spec to_svg(VegaLite.t()) :: binary()
  def to_svg(vl, opts \\ []) do
    node_convert(vl, "svg", "to_svg/1", opts)
  end

  @doc """
  Renders the given graphic into a PDF and returns its
  binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

  * `:local_npm_prefix` - used for `:png`, `:svg`, `:pdf` formats to help locate local npm directory.
    For example in Phoenix projects you need to pass `local_npm_prefix: "assets"`.
  """
  @spec to_pdf(VegaLite.t()) :: binary()
  def to_pdf(vl, opts \\ []) do
    node_convert(vl, "pdf", "to_pdf/1", opts)
  end

  defp node_convert(vl, format, fn_name, opts) do
    json = to_json(vl)
    json_file = System.tmp_dir!() |> Path.join("vega-lite-#{Utils.process_timestamp()}.json")
    File.write!(json_file, json)

    script_path = find_npm_script!("vl2#{format}", fn_name, opts)
    {output, 0} = run_cmd(script_path, [json_file])

    _ = File.rm(json_file)

    output
  end

  defp find_npm_script!(script_name, fn_name, opts) do
    npm_path = System.find_executable("npm")

    unless npm_path do
      raise RuntimeError,
            "#{fn_name} requires Node.js and npm to be installed and available in PATH"
    end

    local_bin_args =
      case opts[:local_npm_prefix] do
        nil -> []
        path -> ["--prefix", path]
      end

    local_bin = npm_bin(npm_path, local_bin_args)
    global_bin = npm_bin(npm_path, ["--global"])

    [local_bin, global_bin]
    |> Enum.map(&npm_script_from_bin(&1, script_name))
    |> Enum.find(fn path -> path != nil end)
    |> case do
      nil ->
        raise RuntimeError, """
        #{fn_name} requires #{script_name} executable from the vega-lite npm package.

        Make sure to install the necessary npm dependencies:

            npm install -g vega vega-lite canvas
            # or in the current directory
            npm install vega vega-lite canvas
        """

      path ->
        path
    end
  end

  defp npm_bin(npm_path, args) do
    {npm_bin, 0} = run_cmd(npm_path, ["bin" | args])
    String.trim(npm_bin)
  end

  defp npm_script_from_bin(bin, script_name) do
    script_path = Path.join(bin, script_name)
    if File.exists?(script_path), do: script_path, else: nil
  end

  def run_cmd(script_path, args) do
    case :os.type() do
      {:win32, _} -> System.cmd("cmd", ["/C", script_path | args])
      {_, _} -> System.cmd(script_path, args)
    end
  end
end
