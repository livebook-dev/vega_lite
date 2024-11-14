# TODO: remove on v1.0
defmodule VegaLite.Export do
  @moduledoc false

  alias VegaLite.Utils

  @deprecated "Use VegaLite.Convert.save!/3 in from the :vega_lite_convert package instead"
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

  @deprecated "Use VegaLite.Convert.to_json/1 in from the :vega_lite_convert package instead"
  @spec to_json(VegaLite.t()) :: String.t()
  def to_json(vl) do
    Utils.assert_jason!("to_json/1")

    vl
    |> VegaLite.to_spec()
    |> Jason.encode!()
  end

  @deprecated "Use VegaLite.Convert.to_html/1 in from the :vega_lite_convert package instead"
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
      <script src="https://cdn.jsdelivr.net/npm/vega@5.28.0"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.18.0"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.24.0"></script>
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

  @doc false
  def to_html_no_deprecation(vl), do: to_html(vl)

  defp escape_double_quotes(json) do
    String.replace(json, ~s{"}, ~s{\\"})
  end

  @deprecated "Use VegaLite.Convert.to_png/1 in from the :vega_lite_convert package instead"
  @spec to_png(VegaLite.t(), keyword()) :: binary()
  def to_png(vl, opts \\ []) do
    node_convert(vl, "png", "to_png/1", opts)
  end

  @deprecated "Use VegaLite.Convert.to_svg/1 in from the :vega_lite_convert package instead"
  @spec to_svg(VegaLite.t(), keyword()) :: binary()
  def to_svg(vl, opts \\ []) do
    node_convert(vl, "svg", "to_svg/1", opts)
  end

  @deprecated "Use VegaLite.Convert.to_pdf/1 in from the :vega_lite_convert package instead"
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
