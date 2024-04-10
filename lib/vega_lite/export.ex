defmodule VegaLite.Export do
  @moduledoc """
  Various export methods for a `VegaLite` specification.

  All of the export functions depend on the `:jason` package.
  Additionally the PNG, SVG and PDF exports rely on npm packages,
  so you will need Node.js, `npm`, and the following dependencies:

  ```console
  $ npm install -g vega vega-lite canvas
  ```

  Alternatively you can install the dependencies in a local directory:

  ```console
  $ npm install vega vega-lite canvas
  ```
  """

  alias VegaLite.Utils

  @doc """
  Saves a `VegaLite` specification to file in one of
  the supported formats.

  ## Options

    * `:format` - the format to export the graphic as,
      must be either of: `:json`, `:html`, `:png`, `:svg`, `:pdf`.
      By default the format is inferred from the file extension.

    * `:local_npm_prefix` - a relative path pointing to a local npm project directory
      where the necessary npm packages are installed. For instance, in Phoenix projects
      you may want to pass `local_npm_prefix: "assets"`. By default the npm packages
      are searched for in the current directory and globally.

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

    * `:local_npm_prefix` - a relative path pointing to a local npm project directory
      where the necessary npm packages are installed. For instance, in Phoenix projects
      you may want to pass `local_npm_prefix: "assets"`. By default the npm packages
      are searched for in the current directory and globally.

  """
  @spec to_png(VegaLite.t(), keyword()) :: binary()
  def to_png(vl, opts \\ []) do
    node_convert(vl, "png", "to_png/1", opts)
  end

  @doc """
  Renders the given graphic as an SVG image and returns
  its binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

    * `:local_npm_prefix` - a relative path pointing to a local npm project directory
      where the necessary npm packages are installed. For instance, in Phoenix projects
      you may want to pass `local_npm_prefix: "assets"`. By default the npm packages
      are searched for in the current directory and globally.

  """
  @spec to_svg(VegaLite.t(), keyword()) :: binary()
  def to_svg(vl, opts \\ []) do
    node_convert(vl, "svg", "to_svg/1", opts)
  end

  @doc """
  Renders the given graphic into a PDF and returns its
  binary content.

  Relies on the `npm` packages mentioned above.

  ## Options

    * `:local_npm_prefix` - a relative path pointing to a local npm project directory
      where the necessary npm packages are installed. For instance, in Phoenix projects
      you may want to pass `local_npm_prefix: "assets"`. By default the npm packages
      are searched for in the current directory and globally.

  """
  @spec to_pdf(VegaLite.t(), keyword()) :: binary()
  def to_pdf(vl, opts \\ []) do
    node_convert(vl, "pdf", "to_pdf/1", opts)
  end

  defp node_convert(vl, format, fn_name, opts) do
    json = to_json(vl)
    json_file = System.tmp_dir!() |> Path.join("vega-lite-#{Utils.process_timestamp()}.json")
    File.write!(json_file, json)

    output = npm_exec!("vl2#{format}", [json_file], fn_name, opts)

    _ = File.rm(json_file)

    output
  end

  defp npm_exec!(command, args, fn_name, opts) do
    npm_path = System.find_executable("npm")

    unless npm_path do
      raise RuntimeError,
            "#{fn_name} requires Node.js and npm to be installed and available in PATH"
    end

    prefix_args =
      case opts[:local_npm_prefix] do
        nil -> []
        path -> ["--prefix", path]
      end

    case run_cmd(
           npm_path,
           ["exec", "--no", "--offline"] ++ prefix_args ++ ["--", command] ++ args
         ) do
      {output, 0} ->
        output

      {_output, code} ->
        raise RuntimeError, """
        #{fn_name} requires #{command} executable from the vega-lite npm package.

        Make sure to install the necessary npm dependencies:

            npm install -g vega vega-lite canvas
            # or in the current directory
            npm install vega vega-lite canvas

        npm exec failed with code #{code}. Errors have been logged to standard error
        """
    end
  end

  def run_cmd(script_path, args) do
    case :os.type() do
      {:win32, _} -> System.cmd("cmd", ["/C", script_path | args])
      {_, _} -> System.cmd(script_path, args)
    end
  end
end
