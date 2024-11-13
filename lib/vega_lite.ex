defmodule VegaLite do
  @moduledoc """
  Elixir bindings to [Vega-Lite](https://vega.github.io/vega-lite).

  Vega-Lite offers a high-level grammar for composing interactive graphics,
  where every graphic is specified in a declarative fashion relying solely
  on JSON syntax. To learn more about Vega-Lite please refer to
  the [documentation](https://vega.github.io/vega-lite/docs)
  and explore numerous [examples](https://vega.github.io/vega-lite/examples).

  This package offers a tiny layer of functionality that makes it easier
  to build a Vega-Lite graphics specification.

  ## Composing graphics

  We offers a light-weight pipeline API akin to the JSON specification.
  Translating existing Vega-Lite specifications to such specification
  should be very intuitive in most cases.

  Composing a basic Vega-Lite graphic usually consists of the following steps:

      alias VegaLite, as: Vl

      # Initialize the specification, optionally with some top-level properties
      Vl.new(width: 400, height: 400)

      # Specify data source for the graphic, see the data_from_* functions
      |> Vl.data_from_values(iteration: 1..100, score: 1..100)
      # |> Vl.data_from_values([%{iteration: 1, score: 1}, ...])
      # |> Vl.data_from_url("...")

      # Pick a visual mark for the graphic
      |> Vl.mark(:line)
      # |> Vl.mark(:point, tooltip: true)

      # Map data fields to visual properties of the mark, like position or shape
      |> Vl.encode_field(:x, "iteration", type: :quantitative)
      |> Vl.encode_field(:y, "score", type: :quantitative)
      # |> Vl.encode_field(:color, "country", type: :nominal)
      # |> Vl.encode_field(:size, "count", type: :quantitative)

  Then, you can compose multiple graphics using `layers/2`, `concat/3`,
  `repeat/3` or `facet/3`.

      Vl.new()
      |> Vl.data_from_url("https://vega.github.io/editor/data/weather.csv")
      |> Vl.transform(filter: "datum.location == 'Seattle'")
      |> Vl.concat([
        Vl.new()
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "date", time_unit: :month, type: :ordinal)
        |> Vl.encode_field(:y, "precipitation", aggregate: :mean),
        Vl.new()
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "temp_min", bin: true)
        |> Vl.encode_field(:y, "temp_max", bin: true)
        |> Vl.encode(:size, aggregate: :count)
      ])

  Additionally, you can use `transform/2` to preprocess the data,
  `param/3` for introducing interactivity and `config/2` for
  global customization.

  > #### Option casing {: .info}
  >
  > Note that the specification uses snake-case instead of camel-case.
  > See [Options](#module-options).

  ### Using JSON specification

  Alternatively you can parse a Vega-Lite JSON specification directly.
  This approach makes it easy to explore numerous examples available online.

      alias VegaLite, as: Vl

      Vl.from_json(\"\"\"
      {
        "data": { "url": "https://vega.github.io/editor/data/cars.json" },
        "mark": "point",
        "encoding": {
          "x": { "field": "Horsepower", "type": "quantitative" },
          "y": { "field": "Miles_per_Gallon", "type": "quantitative" }
        }
      }
      \"\"\")

  The result of `VegaLite.from_json/1` function can then be passed
  through any other function to further customize the specification.
  In particular, it may be useful to parse a JSON specification
  and add your custom data with `VegaLite.data_from_values/3`.

  ## Options

  Most `VegaLite` functions accept an optional list of options,
  which are converted directly as the specification properties.
  To provide a more Elixir-friendly experience, the options
  are automatically normalized, so you can use keyword lists
  and snake-case atom keys. For example, if you specify
  `axis: [label_angle: -45]`, this library will automatically
  rewrite it `labelAngle`, which is the name used by the VegaLite
  specification.

  ## Export

  `VegaLite` graphics can be exported into various formats, such as
  SVG, PNG and PDF thorugh the [`:vega_lite_convert`](https://hexdocs.pm/vega_lite_convert)
  package.
  """

  @schema_url "https://vega.github.io/schema/vega-lite/v5.json"

  defstruct spec: %{"$schema" => @schema_url}

  alias VegaLite.Utils

  @type t :: %__MODULE__{
          spec: spec()
        }

  @type spec :: map()

  @doc """
  Returns a new specification wrapped in the `VegaLite` struct.

  All provided options are converted to top-level properties
  of the specification.

  ## Examples

      Vl.new(
        title: "My graph",
        width: 200,
        height: 200
      )
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    vl = %VegaLite{}
    vl_props = opts_to_vl_props(opts)
    update_in(vl.spec, fn spec -> Map.merge(spec, vl_props) end)
  end

  @compile {:no_warn_undefined, {Jason, :decode!, 1}}

  @doc """
  Parses the given Vega-Lite JSON specification
  and wraps in the `VegaLite` struct for further processing.

  ## Examples

      Vl.from_json(\"\"\"
      {
        "data": { "url": "https://vega.github.io/editor/data/cars.json" },
        "mark": "point",
        "encoding": {
          "x": { "field": "Horsepower", "type": "quantitative" },
          "y": { "field": "Miles_per_Gallon", "type": "quantitative" }
        }
      }
      \"\"\")


  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec from_json(String.t()) :: t()
  def from_json(json) do
    Utils.assert_jason!("from_json/1")

    json
    |> Jason.decode!()
    |> from_spec()
  end

  @doc """
  Wraps the given Vega-Lite specification in the `VegaLite`
  struct for further processing.

  There is also `from_json/1` that handles JSON parsing for you.

  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec from_spec(spec()) :: t()
  def from_spec(spec) do
    %VegaLite{spec: spec}
  end

  @doc """
  Returns the underlying Vega-Lite specification.

  The result is a nested Elixir datastructure that serializes
  to Vega-Lite JSON specification.

  See [the docs](https://vega.github.io/vega-lite/docs/spec.html) for more details.
  """
  @spec to_spec(t()) :: spec()
  def to_spec(vl) do
    vl.spec
  end

  @doc """
  Sets data properties in the specification.

  Defining the data source is usually the first step
  when building a graphic. For most use cases it's preferable
  to use more specific functions like `data_from_url/3` or `data_from_values/3`.

  All provided options are converted to data properties.

  ## Examples

      Vl.new()
      |> Vl.data(sequence: [start: 0, stop: 12.7, step: 0.1, as: "x"])
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/data.html) for more details.
  """
  @spec data(t(), keyword()) :: t()
  def data(vl, opts) do
    validate_at_least_one!(opts, "data property")

    update_in(vl.spec, fn spec ->
      {values, opts} = Keyword.pop(opts, :values)
      vl_props = opts_to_vl_props(opts)
      vl_props = if(values, do: Map.put(vl_props, "values", values), else: vl_props)
      Map.put(spec, "data", vl_props)
    end)
  end

  defp validate_at_least_one!(opts, name) do
    if not is_list(opts) do
      raise ArgumentError, "expected opts to be a list, got: #{inspect(opts)}"
    end

    if opts == [] do
      raise ArgumentError, "expected at least one #{name}, but none was given"
    end
  end

  @doc """
  Sets data URL in the specification.

  The URL should be accessible by whichever client renders
  the specification, so preferably an absolute one.

  All provided options are converted to data properties.

  ## Examples

      Vl.new()
      |> Vl.data_from_url("https://vega.github.io/editor/data/penguins.json")
      |> ...

      Vl.new()
      |> Vl.data_from_url("https://vega.github.io/editor/data/stocks.csv", format: :csv)
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/data.html#url) for more details.
  """
  @spec data_from_url(t(), String.t(), keyword()) :: t()
  def data_from_url(vl, url, opts \\ []) when is_binary(url) do
    opts = put_in(opts[:url], url)
    data(vl, opts)
  end

  @doc """
  Sets inline data in the specification.

  Any tabular data is accepted, as long as it adheres to the
  `Table.Reader` protocol.

  ## Options

    * `:only` - specifies a subset of fields to pick from the data

  All other options are converted to data properties.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Vl.new()
      |> Vl.data_from_values(data)
      |> ...

  Note that any tabular data is accepted, as long as it adheres
  to the `Table.Reader` protocol. For example that's how we can
  pass individual series:

      xs = 1..100
      ys = 1..100

      Vl.new()
      |> Vl.data_from_values(x: xs, y: ys)
      |> ...

  See [the docs](https://vega.github.io/vega-lite/docs/data.html#inline) for more details.
  """
  @spec data_from_values(t(), Table.Reader.t(), keyword()) :: t()
  def data_from_values(vl, values, opts \\ []) do
    {only, opts} = Keyword.pop(opts, :only)
    values = tabular_to_data_values(values, only)
    opts = put_in(opts[:values], values)
    data(vl, opts)
  end

  # Converts enumerable data structure into Vega-Lite compatible data points
  defp tabular_to_data_values(tabular, only) do
    only = only && only |> Enum.map(&to_string/1) |> MapSet.new()

    tabular
    |> Table.to_rows()
    |> Enum.map(fn entry ->
      for {key, value} <- entry,
          key = to_string(key),
          only == nil or MapSet.member?(only, key),
          into: %{},
          do: {key, value}
    end)
  end

  @doc false
  @deprecated "Use VegaLite.data_from_values/3 instead"
  def data_from_series(vl, series, opts \\ []) do
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

  @doc """
  Specifies top-level datasets.

  Datasets can be used as a data source further in the specification.
  This is useful if you need to refer to the data in multiple places
  or use a `transform/2` like `:lookup`.

  Datasets should be a key-value enumerable, where key is the dataset
  name and value is tabular data as in `data_from_values/3`.

  ## Examples

      results = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      points = [
        %{"x" => "1", "y" => 10},
        %{"x" => "2", "y" => 100}
      ]

      Vl.new()
      |> Vl.datasets_from_values(results: results, points: points)
      # Use one of the data sets as the primary data
      |> Vl.data(name: "results")
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/data.html#datasets) for more details.
  """
  @spec datasets_from_values(t(), Enumerable.t()) :: t()
  def datasets_from_values(vl, datasets) do
    datasets =
      for {name, values} <- datasets, into: %{} do
        values = tabular_to_data_values(values, nil)
        {to_string(name), values}
      end

    put_in(vl.spec["datasets"], datasets)
  end

  @channels ~w(
    x y x2 y2 x_error y_error x_error2 y_error2
    x_offset y_offset
    theta theta2 radius radius2
    longitude latitude longitude2 latitude2
    angle color fill stroke opacity fill_opacity stroke_opacity shape size stroke_dash stroke_width
    text tooltip
    href
    url
    description
    detail
    key
    order
    facet row column
  )a

  @doc """
  Adds an encoding entry to the specification.

  Visual channel represents a property of a visual mark,
  for instance the `:x` and `:y` channels specify where
  a point should be placed.
  Encoding defines the source of values for those channels.

  In most cases you want to map specific data field
  to visual channels, prefer the `encode_field/4` function for that.

  All provided options are converted to channel properties.

  ## Examples

      Vl.new()
      |> Vl.encode(:x, value: 2)
      |> ...

      Vl.new()
      |> Vl.encode(:y, aggregate: :count, type: :quantitative)
      |> ...

      Vl.new()
      |> Vl.encode(:y, field: "price")
      |> ...

  Alternatively, a list of property lists may be given:

      Vl.new()
      |> Vl.encode(:tooltip, [
        [field: "height", type: :quantitative],
        [field: "width", type: :quantitative]
      ])
      |> ...

  See [the docs](https://vega.github.io/vega-lite/docs/encoding.html) for more details.
  """
  @spec encode(t(), atom(), keyword() | list(keyword())) :: t()
  def encode(vl, channel, opts) do
    validate_channel!(channel)

    list? = match?([h | _] when is_list(h), opts)

    if list? do
      for opts <- opts, do: validate_channel_opts(opts)
    else
      validate_channel_opts(opts)
    end

    update_in(vl.spec, fn spec ->
      vl_channel = to_vl_key(channel)

      vl_props =
        if list? do
          Enum.map(opts, &opts_to_vl_props/1)
        else
          opts_to_vl_props(opts)
        end

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
      list_str = list |> Enum.map(&inspect/1) |> Enum.join(", ")

      raise ArgumentError,
            "unknown #{name}, expected one of #{list_str}, got: #{inspect(value)}"
    end
  end

  defp validate_channel_opts(opts) do
    if not Enum.any?([:field, :value, :datum], &Keyword.has_key?(opts, &1)) and
         opts[:aggregate] != :count do
      raise ArgumentError,
            "channel definition must include one of the following keys: :field, :value, :datum, but none was given"
    end

    with {:ok, type} <- Keyword.fetch(opts, :type) do
      validate_inclusion!([:quantitative, :temporal, :nominal, :ordinal, :geojson], type, "type")
    end
  end

  @doc """
  Adds field encoding entry to the specification.

  A shorthand for `encode/3`, mapping a data field to a visual channel.

  For example, if the data has `"price"` and `"time"` fields,
  you could map `"time"` to the `:x` channel and `"price"`
  to the `:y` channel. This, combined with a line mark,
  would then result in price-over-time plot.

  All provided options are converted to channel properties.

  ## Types

  Field data type is automatically inferred, but oftentimes
  needs to be specified explicitly to get the desired result.
  The `:type` option can be either of:

    * `:quantitative` - when the field expresses some kind of quantity, typically numerical

    * `:temporal` - when the field represents a point in time

    * `:nominal` - when the field represents a category

    * `:ordinal` - when the field represents a ranked order.
      It is similar to `:nominal`, but there is a clear order of values

    * `:geojson` - when the field represents a geographic shape
      adhering to the [GeoJSON](https://geojson.org) specification

  See [the docs](https://vega.github.io/vega-lite/docs/type.html) for more details on types.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.mark(:point)
      |> Vl.encode_field(:x, "time", type: :temporal)
      |> Vl.encode_field(:y, "price", type: :quantitative)
      |> Vl.encode_field(:color, "country", type: :nominal)
      |> Vl.encode_field(:size, "count", type: :quantitative)
      |> ...

      Vl.new()
      |> Vl.encode_field(:x, "date", time_unit: :month, title: "Month")
      |> Vl.encode_field(:y, "price", type: :quantitative, aggregate: :mean, title: "Mean product price")
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/encoding.html#field-def) for more details.
  """
  @spec encode_field(t(), atom(), String.t(), keyword()) :: t()
  def encode_field(vl, channel, field, opts \\ []) do
    if not is_binary(field) do
      raise ArgumentError, "field must be a string, got: #{inspect(field)}"
    end

    opts = put_in(opts[:field], field)
    encode(vl, channel, opts)
  end

  @doc """
  Adds repeated field encoding entry to the specification.

  A shorthand for `encode/3`, mapping a field to a visual channel,
  as given by the repeat operator.

  Repeat type must be either `:repeat`, `:row`, `:column` or `:layer`
  and correspond to the repeat definition.

  All provided options are converted to channel properties.

  ## Examples

  See `repeat/3` to see the full picture.

  See [the docs](https://vega.github.io/vega-lite/docs/repeat.html) for more details.
  """
  @spec encode_repeat(t(), atom(), :repeat | :row | :column | :layer, keyword()) :: t()
  def encode_repeat(vl, channel, repeat_type, opts \\ []) do
    validate_inclusion!([:repeat, :row, :column, :layer], repeat_type, "repeat type")

    opts = Keyword.put(opts, :field, repeat: repeat_type)
    encode(vl, channel, opts)
  end

  @mark_types ~w(
    arc area bar boxplot circle errorband errorbar geoshape image line point rect rule square text tick trail
  )a

  @doc """
  Sets mark type in the specification.

  Mark is a predefined visual object like a point or a line.
  Visual properties of the mark are defined by encoding.

  All provided options are converted to mark properties.

  ## Examples

      Vl.new()
      |> Vl.mark(:point)
      |> ...

      Vl.new()
      |> Vl.mark(:point, tooltip: true)
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/mark.html) for more details.
  """
  @spec mark(t(), atom(), keyword()) :: t()
  def mark(vl, type, opts \\ [])

  def mark(vl, type, []) do
    validate_blank_view!(vl, "cannot add mark to the view")
    validate_inclusion!(@mark_types, type, "mark type")

    update_in(vl.spec, fn spec ->
      vl_type = to_vl_key(type)
      Map.put(spec, "mark", vl_type)
    end)
  end

  def mark(vl, type, opts) do
    validate_blank_view!(vl, "cannot add mark to the view")
    validate_inclusion!(@mark_types, type, "mark type")

    update_in(vl.spec, fn spec ->
      vl_type = to_vl_key(type)

      vl_props =
        opts
        |> opts_to_vl_props()
        |> Map.put("type", vl_type)

      Map.put(spec, "mark", vl_props)
    end)
  end

  @doc """
  Adds a transformation to the specification.

  Transformation describes an operation on data,
  like calculating new fields, aggregating or filtering.

  All provided options are converted to transform properties.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.transform(calculate: "sin(datum.x)", as: "sin_x")
      |> ...

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.transform(filter: "datum.height > 150")
      |> ...

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.transform(regression: "price", on: "date")
      |> ...


  See [the docs](https://vega.github.io/vega-lite/docs/transform.html) for more details.
  """
  @spec transform(t(), keyword()) :: t()
  def transform(vl, opts) do
    validate_at_least_one!(opts, "transform property")

    update_in(vl.spec, fn spec ->
      transforms = Map.get(spec, "transform", [])
      transform = opts_to_vl_props(opts)
      Map.put(spec, "transform", transforms ++ [transform])
    end)
  end

  @doc """
  Adds a parameter to the specification.

  Parameters are the basic building blocks for introducing
  interactions to graphics.

  All provided options are converted to parameter properties.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.concat([
        Vl.new()
        # Define a parameter named "brush", whose value is a user-selected interval on the x axis
        |> Vl.param("brush", select: [type: :interval, encodings: [:x]])
        |> Vl.mark(:area)
        |> Vl.encode_field(:x, "date", type: :temporal)
        |> ...,
        Vl.new()
        |> Vl.mark(:area)
        # Use the "brush" parameter value to limit the domain of this view
        |> Vl.encode_field(:x, "date", type: :temporal, scale: [domain: [param: "brush"]])
        |> ...
      ])

    Parameters can also be specified using UI inputs, or computed based
    on other parameters:

      Vl.new()
      |> Vl.param("height", value: 20, bind: [input: :range, min: 1, max: 100, step: 1])
      |> Vl.param("halfHeight", expr: "height / 2")
      |> ...

  See [the docs](https://vega.github.io/vega-lite/docs/parameter.html) for more details.
  """
  @spec param(t(), String.t(), keyword()) :: t()
  def param(vl, name, opts) do
    validate_at_least_one!(opts, "parameter property")

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
  Adds view configuration to the specification.

  Configuration allows for setting general properties of the visualization.

  All provided options are converted to configuration properties
  and merged with the existing configuration in a shallow manner.

  ## Examples

      Vl.new()
      |> ...
      |> Vl.config(
        view: [stroke: :transparent],
        padding: 100,
        background: "#333333"
      )


  See [the docs](https://vega.github.io/vega-lite/docs/config.html) for more details.
  """
  @spec config(t(), keyword()) :: t()
  def config(vl, opts) do
    validate_at_least_one!(opts, "config property")

    update_in(vl.spec, fn spec ->
      vl_props = opts_to_vl_props(opts)

      config =
        spec
        |> Map.get("config", %{})
        |> Map.merge(vl_props)

      Map.put(spec, "config", config)
    end)
  end

  @doc """
  Adds a projection spec to the specification.

  Projection maps longitude and latitude pairs to x, y coordinates.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.projection(type: :albers_usa)
      |> Vl.mark(:circle)
      |> Vl.encode_field(:longitude, "longitude", type: :quantitative)
      |> Vl.encode_field(:latitude, "latitude", type: :quantitative)


  See [the docs](https://vega.github.io/vega-lite/docs/projection.html) for more details.
  """
  @spec projection(t(), keyword()) :: t()
  def projection(vl, opts) do
    validate_at_least_one!(opts, "projection property")

    update_in(vl.spec, fn spec ->
      vl_props = opts_to_vl_props(opts)
      Map.put(spec, "projection", vl_props)
    end)
  end

  @doc """
  Builds a layered multi-view specification from the given
  list of single view specifications.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.layers([
        Vl.new()
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, ...)
        |> Vl.encode_field(:y, ...),
        Vl.new()
        |> Vl.mark(:rule)
        |> Vl.encode_field(:y, ...)
        |> Vl.encode(:size, value: 2)
      ])

      Vl.new()
      |> Vl.data_from_values(...)
      # Note: top-level data, encoding, transforms are inherited
      # by the child views unless overridden
      |> Vl.encode_field(:x, ...)
      |> Vl.layers([
        ...
      ])


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

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.concat([
        Vl.new()
        |> ...,
        Vl.new()
        |> ...,
        Vl.new()
        |> ...
      ])

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.concat(
        [
          Vl.new()
          |> ...,
          Vl.new()
          |> ...
        ],
        :horizontal
      )


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

  Note that you can also create facet graphics by using
  the `:facet`, `:column` and `:row` encoding channels.

  ## Examples

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.facet(
        [field: "country"],
        Vl.new()
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, ...)
        |> Vl.encode_field(:y, ...)
      )

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.facet(
        [
          row: [field: "country", title: "Country"],
          column: [field: "year", title: "Year"]
        ]
        Vl.new()
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, ...)
        |> Vl.encode_field(:y, ...)
      )


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
                "facet definition must be either a field definition (keyword list with the :field key) or a mapping with :row/:column keys, got: #{inspect(facet_def)}"
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
  Then some channels can be bound to a repeated field using `encode_repeat/4`.

  ## Examples

      # Simple repeat
      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.repeat(
        ["temp_max", "precipitation", "wind"],
        Vl.new()
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, "date", time_unit: :month)
        # The graphic will be reapeated with :y mapped to "temp_max",
        # "precipitation" and "wind" respectively
        |> Vl.encode_repeat(:y, :repeat, aggregate: :mean)
      )

      # Grid repeat
      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.repeat(
        [
          row: [
            "beak_length",
            "beak_depth",
            "flipper_length",
            "body_mass"
          ],
          column: [
            "body_mass",
            "flipper_length",
            "beak_depth",
            "beak_length"
          ]
        ],
        Vl.new()
        |> Vl.mark(:point)
        # The graphic will be repeated for every combination of :x and :y
        # taken from the :row and :column lists above
        |> Vl.encode_repeat(:x, :column, type: :quantitative)
        |> Vl.encode_repeat(:y, :row, type: :quantitative)
      )


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
      raise ArgumentError,
            "#{error_message}, because it is already a multi-view specification (has the #{inspect(key)} key defined)"
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

  ## Example

      Vl.new()
      |> Vl.data_from_values(...)
      |> Vl.layers([
        Vl.new()
        |> ...,
        Vl.new()
        |> ...
      ])
      |> Vl.resolve(:scale, y: :independent)


  See [the docs](https://vega.github.io/vega-lite/docs/resolve.html) for more details.
  """
  @spec resolve(t(), atom(), keyword()) :: t()
  def resolve(vl, key, opts) do
    validate_inclusion!(@resolve_keys, key, "resolution key")
    validate_at_least_one!(opts, "resolve property")

    for {channel, resolution} <- opts do
      validate_inclusion!(@channels, channel, "resolution channel")
      validate_inclusion!([:shared, :independent], resolution, "resolution type")
    end

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

  defp to_vl(%_{} = struct), do: struct

  defp to_vl(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl([{key, _} | _] = keyword) when is_atom(key) do
    Map.new(keyword, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl(list) when is_list(list) do
    Enum.map(list, &to_vl/1)
  end

  defp to_vl(value), do: value

  defp to_vl_key(key) when is_atom(key) do
    key |> to_string() |> snake_to_camel()
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &capitalize/1)])
  end

  defp capitalize(<<first, rest::binary>>) when first in ?a..?z, do: <<first - 32, rest::binary>>
  defp capitalize(rest), do: rest
end
