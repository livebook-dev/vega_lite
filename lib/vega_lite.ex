defmodule VegaLite do
  @doc """
  Elixir bindings to [Vega-Lite](https://vega.github.io/vega-lite).

  Vega-Lite offers a high-level grammar for composing interactive graphics,
  where every graphic is specified in a declarative fashion relying solely
  on JSON syntax.

  This package offers a tiny layer of functionality that makes it easier
  to build a Vega-Lite graphic specification.

  To learn more about Vega-Lite please refer to the [documentation](https://vega.github.io/vega-lite/docs)
  and explore numerous [examples](https://vega.github.io/vega-lite/examples).

  ## Usage

  There are two ways of building graphic view specification,
  one Elixir-centric and the other compatibility-centric.

  ### Pipeline API

  We offers a light-weight pipeline API akin to the JSON specification.
  Translating existing Vega-Lite specifications to such specification
  should be very intuitive in most cases.

  A simple line chart could be composed like this:

      alias VegaLite, as: Vl

      Vl.new(width: 400, height: 400)
      |> Vl.data_from_series(x: 1..100, y: 1..100)
      |> Vl.mark(:line)
      |> Vl.encode_field(:x, "x", type: :quantitative)
      |> Vl.encode_field(:y, "y", type: :quantitative)

  ### JSON specification

  Alternatively you can parse a Vega-Lite JSON specification directly.
  This approach makes it easy to explore numerous examples available online.

      alias VegaLite, as: Vl

      Vl.from_json(\"\"\"
      {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "description": "A scatterplot showing body mass and flipper lengths of penguins.",
        "data": {
          "url": "https://vega.github.io/editor/data/penguins.json"
        },
        "mark": "point",
        "encoding": {
          "x": {
            "field": "Flipper Length (mm)",
            "type": "quantitative",
            "scale": {"zero": false}
          },
          "y": {
            "field": "Body Mass (g)",
            "type": "quantitative",
            "scale": {"zero": false}
          },
          "color": {"field": "Species", "type": "nominal"},
          "shape": {"field": "Species", "type": "nominal"}
        }
      }
      \"\"\")

  The result of `VegaLite.from_json/1` function can then be passed
  through any other function to further customize the specification.
  In particular, it may be useful to parse a JSON specification
  and add your custom data with `VegaLite.data_from_values/3`
  or `VegaLite.data_from_series/3`.

  ## Options

  Most `VegaLite` functions accept an optional list of options,
  which are included directly as the specification properties.
  To provide a more Elixir-friendly experience, the options
  are automatically normalized, so you can use keyword lists
  and snake-case atom keys.
  """

  @schema_url "https://vega.github.io/schema/vega-lite/v5.json"

  defstruct spec: %{"$schema" => @schema_url}

  @type t :: %__MODULE__{
          spec: spec()
        }

  @type spec :: map()

  @doc """
  Returns a new specification wrapped in the `VegaLite` struct.

  All provided options are used as top-level properties
  of the specification.

  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    vl = %VegaLite{}
    vl_props = opts_to_vl_props(opts)
    update_in(vl.spec, fn spec -> Map.merge(spec, vl_props) end)
  end

  @doc """
  Parses the given Vega-Lite JSON specification
  and wraps in the `VegaLite` struct for further processing.

  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec from_json(String.t()) :: t()
  def from_json(json) do
    spec = Jason.decode!(json)
    %VegaLite{spec: spec}
  end

  @doc """
  Returns the underlying Vega-Lite specification.

  The result is a nested Elixir datastructure that serializes
  to an appropriate JSON specification.

  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec to_spec(t()) :: spec()
  def to_spec(vl) do
    vl.spec
  end

  @doc """
  Adds data URL to the specification.

  The URL should be accessible by whichever client renders
  the specification, so preferably an absolute one.

  See [the docs](https://vega.github.io/vega-lite/docs/data.html#url) for more details.
  """
  @spec data_from_url(t(), String.t(), keyword()) :: t()
  def data_from_url(vl, url, opts \\ []) when is_binary(url) do
    update_in(vl.spec, fn spec ->
      vl_props =
        opts
        |> opts_to_vl_props()
        |> Map.put("url", url)

      Map.put(spec, "data", vl_props)
    end)
  end

  @doc """
  Adds inline data to the specification.

  `values` should be an enumerable of data records,
  where each record is a key-value structure.

  See [the docs](https://vega.github.io/vega-lite/docs/data.html#inline) for more details.
  """
  @spec data_from_values(t(), Enumerable.t(), keyword()) :: t()
  def data_from_values(vl, values, opts \\ []) do
    values =
      Enum.map(values, fn value ->
        Map.new(value, fn {key, value} ->
          {to_string(key), value}
        end)
      end)

    update_in(vl.spec, fn spec ->
      vl_props =
        opts
        |> opts_to_vl_props()
        |> Map.put("values", values)

      Map.put(spec, "data", vl_props)
    end)
  end

  @doc """
  Adds inline data to the specification.

  This is an alternative to `data_from_values/3`,
  useful when you have a separate list of values
  for each column.
  """
  @spec data_from_series(t(), Enumerable.t(), keyword()) :: t()
  def data_from_series(vl, series, opts \\ []) when is_list(series) do
    {keys, value_series} = Enum.unzip(series)

    values =
      value_series
      |> Enum.zip()
      |> Enum.map(fn row ->
        row = Tuple.to_list(row)
        Enum.zip(keys, row)
      end)

    data_from_values(vl, values, opts)
  end

  @channels ~w(
    x y x2 y2 x_error y_error x_error2 y_error2
    theta theta2 radius radius2
    longitude latitude longitude2 latitude2
    angle color fill stroke opacity fill_opacity stroke_opacity shape size stroke_dash stroke_width
    text tooltip
    href
    description
    detail
    key
    order
    facet row column
  )a

  @doc """
  Adds an encoding entry to the specification.

  Encoding maps a property of data to a visual property
  of the given graphical mark (like position or shape).

  See [the docs](https://vega.github.io/vega-lite/docs/encoding.html) for more details.
  """
  @spec encode(t(), atom(), keyword()) :: t()
  def encode(vl, channel, opts \\ []) do
    validate_channel!(channel)

    if not Enum.any?([:field, :value, :datum], &Keyword.has_key?(opts, &1)) and
         opts[:aggregate] != :count do
      raise ArgumentError,
            "channel definition must include one of the following keys: :field, :value, :datum, but none was given"
    end

    update_in(vl.spec, fn spec ->
      vl_channel = to_vl_key(channel)
      vl_props = opts_to_vl_props(opts)

      encoding =
        spec
        |> Map.get("encoding", %{})
        |> Map.put(vl_channel, vl_props)

      Map.put(spec, "encoding", encoding)
    end)
  end

  defp validate_channel!(channel) do
    validate_inclusion!(@channels, channel, "channel")
  end

  defp validate_inclusion!(list, value, name) do
    if value not in list do
      list_str = @channels |> Enum.map(&inspect/1) |> Enum.join(", ")

      raise ArgumentError,
            "unknown #{name}, expected one of #{list_str}, got: #{inspect(value)}"
    end
  end

  @doc """
  Adds field encoding entry to the specification.

  A shorthand for `encode/3` for mapping channel to a data field.

  See [the docs](https://vega.github.io/vega-lite/docs/encoding.html#field-def) for more details.
  """
  @spec encode_field(t(), atom(), String.t(), keyword()) :: t()
  def encode_field(vl, channel, field, opts \\ []) do
    if not is_binary(field) do
      raise ArgumentError, "field must be a string, got: #{inspect(field)}"
    end

    opts = Keyword.put(opts, :field, field)
    encode(vl, channel, opts)
  end

  @doc """
  Adds repeated field encoding entry to the specification.

  A shorthand for `encode/3` for mapping channel to a repeated data field.

  Repeat type must be either `:row`, `:column` or `:layer`.

  See [the docs](https://vega.github.io/vega-lite/docs/encoding.html#field-def) for more details.
  """
  @spec encode_repeat(t(), atom(), :row | :column | :layer, keyword()) :: t()
  def encode_repeat(vl, channel, repeat_type, opts \\ []) do
    if repeat_type not in [:row, :column, :layer] do
      raise ArgumentError,
            "invalid repeat type, expected :row, :column or :layer, got: #{inspect(repeat_type)}"
    end

    opts = Keyword.put(opts, :field, repeat: repeat_type)
    encode(vl, channel, opts)
  end

  @mark_types ~w(
    arc area bar boxplot circle errorband errorbar geoshape image line point rec rule square text tick trail
  )a

  @doc """
  Sets mark type in the specification.

  Mark is a predefined visual object like a point or a line.
  Visual properties of the mark are defined by encoding.

  See [the docs](https://vega.github.io/vega-lite/docs/mark.html) for more details.
  """
  @spec mark(t(), atom(), keyword()) :: t()
  def mark(vl, type, opts \\ [])

  def mark(vl, type, []) do
    validate_blank_view!(vl, "cannot add mark to the view")
    validate_mark_type!(type)

    update_in(vl.spec, fn spec ->
      vl_type = to_vl_key(type)
      Map.put(spec, "mark", vl_type)
    end)
  end

  def mark(vl, type, opts) do
    validate_blank_view!(vl, "cannot add mark to the view")
    validate_mark_type!(type)

    update_in(vl.spec, fn spec ->
      vl_type = to_vl_key(type)

      vl_props =
        opts
        |> opts_to_vl_props()
        |> Map.put("type", vl_type)

      Map.put(spec, "mark", vl_props)
    end)
  end

  defp validate_mark_type!(type) do
    if type not in @mark_types do
      types_str = @mark_types |> Enum.map(&inspect/1) |> Enum.join(", ")

      raise ArgumentError,
            "unknown mark type, expected one of #{types_str}, got: #{inspect(type)}"
    end
  end

  @doc """
  Adds a transformation to the specification.

  Transformation describes an operation on data,
  like calculating new fields, aggregating or filtering.

  See [the docs](https://vega.github.io/vega-lite/docs/transform.html) for more details.
  """
  @spec transform(t(), keyword()) :: t()
  def transform(vl, opts) do
    update_in(vl.spec, fn spec ->
      transforms = Map.get(spec, "transform", [])
      transform = opts_to_vl_props(opts)
      Map.put(spec, "transform", transforms ++ [transform])
    end)
  end

  @doc """
  Adds a parameter to the specification.

  Parameter is the basic building block for introducing
  interactions to graphics.

  See [the docs](https://vega.github.io/vega-lite/docs/parameter.html) for more details.
  """
  @spec parameter(t(), String.t(), keyword()) :: t()
  def parameter(vl, name, opts \\ []) do
    update_in(vl.spec, fn spec ->
      params = Map.get(spec, "params", [])

      param =
        opts
        |> opts_to_vl_props()
        |> Map.put("name", name)

      Map.put(spec, "params", params ++ [param])
    end)
  end

  @doc """
  Adds a config entry to the specification.

  Configuration allows for setting properties of the visualization.

  See [the docs](https://vega.github.io/vega-lite/docs/config.html) for more details.
  """
  @spec config(t(), atom(), keyword()) :: t()
  def config(vl, key, opts \\ []) do
    if not is_atom(key) do
      raise ArgumentError, "config key must be an atom, got: #{inspect(key)}"
    end

    update_in(vl.spec, fn spec ->
      vl_key = to_vl_key(key)
      vl_props = opts_to_vl_props(opts)

      config =
        spec
        |> Map.get("config", %{})
        |> Map.put(vl_key, vl_props)

      Map.put(spec, "config", config)
    end)
  end

  @doc """
  Adds a projection spec to the specification.

  Projection maps longitude and latitude pairs to x, y coordinates.

  See [the docs](https://vega.github.io/vega-lite/docs/projection.html) for more details.
  """
  @spec projection(t(), keyword()) :: t()
  def projection(vl, opts) do
    update_in(vl.spec, fn spec ->
      vl_props = opts_to_vl_props(opts)
      Map.put(spec, "projection", vl_props)
    end)
  end

  @doc """
  Builds a layered multi-view specification from the given
  list of single view specifications.

  See [the docs](https://vega.github.io/vega-lite/docs/layer.html) for more details.
  """
  @spec layers(t(), list(t())) :: t()
  def layers(vl, child_views) do
    multi_view_from_children(vl, child_views, "layer", "cannot build a layered view")
  end

  @doc """
  Builds a concatenated multi-view specification from
  the given list of single view specifications.

  The concat type must be either `:wrappable` (default), `:horizontal` or `:vertical`.

  See [the docs](https://vega.github.io/vega-lite/docs/concat.html) for more details.
  """
  @spec concat(t(), list(t()), :wrappable | :horizontal | :vertical) :: t()
  def concat(vl, child_views, type \\ :wrappable) do
    vl_key =
      case type do
        :wrappable ->
          "concat"

        :horizontal ->
          "hconcat"

        :vertical ->
          "vconcat"

        type ->
          raise ArgumentError,
                "invalid concat type, expected :wrappable, :horizontal or :vertical, got: #{inspect(type)}"
      end

    multi_view_from_children(vl, child_views, vl_key, "cannot build a concatenated view")
  end

  defp multi_view_from_children(vl, child_views, vl_key, error_message) do
    validate_blank_view!(vl, error_message)

    child_specs = Enum.map(child_views, &to_child_view_spec!/1)

    update_in(vl.spec, fn spec ->
      Map.put(spec, vl_key, child_specs)
    end)
  end

  @doc """
  Builds a facet multi-view specification from the given
  single-view template.

  Facet definition must be either a [field definition](https://vega.github.io/vega-lite/docs/facet.html#field-def)
  or a [row/column mapping](https://vega.github.io/vega-lite/docs/facet.html#mapping).

  See [the docs](https://vega.github.io/vega-lite/docs/facet.html#facet-operator) for more details.
  """
  @spec facet(t(), keyword(), t()) :: t()
  def facet(vl, facet_def, child_view) do
    validate_blank_view!(vl, "cannot build a facet view")

    vl_facet =
      cond do
        Keyword.keyword?(facet_def) and
            Enum.any?([:field, :row, :column], &Keyword.has_key?(facet_def, &1)) ->
          opts_to_vl_props(facet_def)

        true ->
          raise ArgumentError,
                "facet definition must be either a field definition (keywrod list with the :field key) or a mapping with :row/:column keys, got: #{inspect(facet_def)}"
      end

    child_spec = to_child_view_spec!(child_view)

    update_in(vl.spec, fn spec ->
      spec
      |> Map.put("facet", vl_facet)
      |> Map.put("spec", child_spec)
    end)
  end

  @doc """
  Builds a repeated multi-view specification from the given
  single-view template.

  Repeat definition must be either a list of fields
  or a [row/column/layer mapping](https://vega.github.io/vega-lite/docs/repeat.html#repeat-mapping).

  See [the docs](https://vega.github.io/vega-lite/docs/repeat.html) for more details.
  """
  @spec repeat(t(), keyword(), t()) :: t()
  def repeat(vl, repeat_def, child_view) do
    validate_blank_view!(vl, "cannot build a repeated view")

    vl_repeat =
      cond do
        is_list(repeat_def) and Enum.all?(repeat_def, &is_binary/1) ->
          repeat_def

        Keyword.keyword?(repeat_def) and
            Enum.any?([:row, :column, :layer], &Keyword.has_key?(repeat_def, &1)) ->
          opts_to_vl_props(repeat_def)

        true ->
          raise ArgumentError,
                "repeat definition must be either list of fields or a mapping with :row/:column/:layer keys, got: #{inspect(repeat_def)}"
      end

    child_spec = to_child_view_spec!(child_view)

    update_in(vl.spec, fn spec ->
      spec
      |> Map.put("repeat", vl_repeat)
      |> Map.put("spec", child_spec)
    end)
  end

  @single_view_only_keys ~w(mark)a
  @multi_view_only_keys ~w(layer hconcat vconcat concat repeat facet spec)a

  # Validates if the given specification is already either single-view or multi-view
  defp validate_blank_view!(vl, error_message) do
    for key <- @single_view_only_keys, Map.has_key?(vl.spec, to_vl_key(key)) do
      raise ArgumentError,
            "#{error_message}, because it is already a single-view specification (has the #{inspect(key)} key defined)"
    end

    for key <- @multi_view_only_keys, Map.has_key?(vl.spec, to_vl_key(key)) do
      if Map.has_key?(vl.spec, key) do
        raise ArgumentError,
              "#{error_message}, because it is already a multi-view specification (has the #{inspect(key)} key defined)"
      end
    end
  end

  @top_level_keys ~w($schema background padding autosize config usermeta)a

  defp to_child_view_spec!(vl) do
    spec = vl |> to_spec() |> Map.delete("$schema")

    for key <- @top_level_keys, Map.has_key?(spec, to_vl_key(key)) do
      raise ArgumentError,
            "child view specification cannot have top-level keys, found: #{inspect(key)}"
    end

    spec
  end

  @resolve_keys ~w(scale axis legend)a

  @doc """
  Adds a resolve entry to the specification.

  Resolution defines how multi-view graphics are combined
  with regard to scales, axis and legend.

  See [the docs](https://vega.github.io/vega-lite/docs/resolve.html) for more details.
  """
  @spec resolve(t(), atom(), keyword()) :: t()
  def resolve(vl, key, opts \\ []) do
    validate_inclusion!(@resolve_keys, key, "resolution key")

    update_in(vl.spec, fn spec ->
      vl_key = to_vl_key(key)
      vl_props = opts_to_vl_props(opts)

      config =
        spec
        |> Map.get("resolve", %{})
        |> Map.put(vl_key, vl_props)

      Map.put(spec, "resolve", config)
    end)
  end

  # Helpers

  defp opts_to_vl_props(opts) do
    opts |> Map.new() |> to_vl()
  end

  defp to_vl(value) when value in [true, false, nil], do: value

  defp to_vl(atom) when is_atom(atom), do: to_vl_key(atom)

  defp to_vl(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_vl_key(key), to_vl(value)}
    end)
  end

  defp to_vl([{key, _} | _] = keyword) when is_atom(key) do
    Map.new(keyword, fn {key, value} ->
      {to_vl_key(key), to_vl(value)}
    end)
  end

  defp to_vl(value), do: value

  defp to_vl_key(key) when is_atom(key) do
    key |> to_string() |> snake_to_camel()
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part) | Enum.map(parts, &String.capitalize/1)])
  end
end
