defmodule VegaLite.Data do
  @moduledoc """
  Data is a VegaLite module designed to provide a shorthand API for commonly used charts and
  high-level abstractions for specialized plots.

  Optionally accepts and always returns a valid `VegaLite` spec, fostering flexibility to be used
  alone or in combination with the `VegaLite` module at any level and at any point.

  It relies on internal type inference, and although all options can be overridden,
  only data that implements the `Table.Reader` protocol is supported.
  """

  alias VegaLite, as: Vl

  @doc """
  Returns the specification for the a given data, a mark, and a list of
  fields to be encoded.

  The `mark` is either an atom, such as `:line`, or a keyword list such as
  `[type: :point, line: true]`.

  It encodes only the given fields from the data by default. More fields can
  be added using the `:extra_fields` option. All the other fields must follow
  the specifications of the `VegaLite` module.

  ## Options

    * `:extra_fields` - adds extra fields to the data subset for later use

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Data.chart(data, :bar, x: "category", y: "score")

      Data.chart(data, :bar, x: "category", extra_fields: ["score"])
      |> Vl.encode_field(:y, "score", type: :quantitative)

  The above examples achieves the same results as the example below.

      Vl.new()
      |> Vl.data_from_values(data, only: ["category", "score"])
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, "category", type: :nominal)
      |> Vl.encode_field(:y, "score", type: :quantitative)

  This function may also be called with an existing VegaLite spec and
  without a mark:

      Vl.new()
      |> Vl.mark(:bar)
      |> Data.chart(data, x: "category", extra_fields: ["score"])

  In such cases it is your responsibility to encode the mark.
  """
  @spec chart(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def chart(%Vl{} = vl, data, fields) do
    chart_no_data(vl, data, fields)
    |> attach_data(data, fields)
  end

  @spec chart(Table.Reader.t(), atom() | keyword(), keyword()) :: VegaLite.t()
  def chart(data, mark, fields), do: chart(Vl.new(), data, mark, fields)

  defp chart_no_data(vl, data, fields) do
    encode_fields(vl, normalize_fields(fields), columns_for(data))
  end

  @doc """
  Same as chart/3 but receives a valid `VegaLite` specification as a first argument.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Vl.new(title: "With title")
      |> Data.chart(data, :bar, x: "category", y: "score")

      Vl.new(title: "With title")
      |> Vl.mark(:bar)
      |> Data.chart(data, x: "category", y: "score")

  The above example achieves the same results as the example below.

      Vl.new(title: "With title")
      |> Vl.data_from_values(data, only: ["category", "score"])
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, "category", type: :nominal)
      |> Vl.encode_field(:y, "score", type: :quantitative)
  """
  @spec chart(VegaLite.t(), Table.Reader.t(), atom() | keyword(), keyword()) :: VegaLite.t()
  def chart(vl, data, mark, fields) do
    chart_no_data(vl, data, mark, fields)
    |> attach_data(data, fields)
  end

  defp chart_no_data(vl, data, mark, fields) do
    vl
    |> encode_mark(mark)
    |> encode_fields(normalize_fields(fields), columns_for(data))
  end

  @doc """
  Returns the specification of a heat map for a given data and a list of fields to be encoded.

  As a specialized chart, the heatmap expects an `:x` and `:y` and optionally a `:color`, a
  `:text` and a `:text_color` fields. Defaults to `:nominal` for the axes and `:quantitative`
  for color and text if types are not specified.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Data.heatmap(data, x: "category", y: "score", color: "score", text: "category")

  With an existing VegaLite spec:

      Vl.new(title: "Heatmap", width: 500)
      |> Data.heatmap(data, x: "category", y: "score", color: "score", text: "category")
  """
  @spec heatmap(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def heatmap(vl \\ Vl.new(), data, fields) do
    for key <- [:x, :y], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a heatmap"
    end

    heatmap_no_data(vl, data, fields, &heatmap_defaults/2)
    |> attach_data(data, fields)
  end

  defp heatmap_no_data(vl, data, fields, fun) do
    cols = columns_for(data)
    fields = normalize_fields(fields, fun)
    text_fields = Keyword.take(fields, [:text, :text_color, :x, :y])
    rect_fields = Keyword.drop(fields, [:text, :text_color])

    {text_color, text_fields} = Keyword.pop(text_fields, :text_color)

    text_fields =
      if text_color, do: Keyword.put_new(text_fields, :color, text_color), else: text_fields

    text_layer = if fields[:text], do: [encode_layer(cols, :text, text_fields)], else: []
    rect_layer = [encode_layer(cols, :rect, rect_fields)]

    Vl.layers(vl, rect_layer ++ text_layer)
  end

  defp heatmap_defaults(field, opts) when field in [:x, :y] do
    Keyword.put_new(opts, :type, :nominal)
  end

  defp heatmap_defaults(field, opts) when field in [:color, :text] do
    Keyword.put_new(opts, :type, :quantitative)
  end

  defp heatmap_defaults(_field, opts), do: opts

  @doc """
  Returns the specification of a density heat map for a given data and a list of fields to be encoded.

  As a specialized chart, the density heatmap expects the `:x` and `:y` axes, a `:color` field and
  optionally a `:text` and a `:text_color` fields. All data must be `:quantitative` and the default
  aggregation function is `:count`.

  ## Examples

      data = [
        %{"total_bill" => 16.99, "tip" => 1.0},
        %{"total_bill" => 10.34, "tip" => 1.66}
      ]

      Data.density_heatmap(data, x: "total_bill", y: "tip", color: "total_bill", text: "tip")

  With an existing VegaLite spec:

      Vl.new(title: "Density Heatmap", width: 500)
      |> Data.heatmap(data, x: "total_bill", y: "tip", color: "total_bill", text: "tip")
  """
  @spec density_heatmap(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def density_heatmap(vl \\ Vl.new(), data, fields) do
    for key <- [:x, :y, :color], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a density heatmap"
    end

    heatmap_no_data(vl, data, fields, &density_heatmap_defaults/2)
    |> attach_data(data, fields)
  end

  defp density_heatmap_defaults(field, opts) when field in [:x, :y] do
    opts |> Keyword.put_new(:type, :quantitative) |> Keyword.put_new(:bin, true)
  end

  defp density_heatmap_defaults(field, opts) when field in [:color, :text] do
    opts |> Keyword.put_new(:type, :quantitative) |> Keyword.put_new(:aggregate, :count)
  end

  defp density_heatmap_defaults(_field, opts), do: opts

  @doc """
  Returns the specification of a joint plot with marginal histograms for a given data and a
  list of fields to be encoded.

  As a specialized chart, the jointplot expects an `:x` and `:y` and optionally a `:color` and a
  `:text` field. All data must be `:quantitative`.

  Besides all marks, it supports `:density_heatmap` as a special value.

  All customizations apply to the main chart only. The marginal histograms are not customizable.

  ## Examples

      data = [
        %{"total_bill" => 16.99, "tip" => 1.0},
        %{"total_bill" => 10.34, "tip" => 1.66}
      ]

      Data.joint_plot(data, :bar, x: "total_bill", y: "tip")

  With an existing VegaLite spec:

      Vl.new(title: "Joint Plot", width: 500)
      |> Data.joint_plot(data, :bar, x: "total_bill", y: "tip", color: "total_bill")
  """
  @spec joint_plot(VegaLite.t(), Table.Reader.t(), atom() | keyword(), keyword()) :: VegaLite.t()
  def joint_plot(vl \\ Vl.new(), data, mark, fields) do
    for key <- [:x, :y], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a jointplot"
    end

    root_opts =
      Enum.filter([width: vl.spec["width"], height: vl.spec["height"]], fn {_k, v} -> v end)

    main_chart = build_main_jointplot(Vl.new(root_opts), data, mark, fields)
    {x_hist, y_hist} = build_marginal_jointplot(normalize_fields(fields), root_opts)

    vl
    |> Map.update!(:spec, &Map.merge(&1, %{"bounds" => "flush", "spacing" => 15}))
    |> attach_data(data, fields)
    |> Vl.concat(
      [x_hist, Vl.new(spacing: 15, bounds: :flush) |> Vl.concat([main_chart, y_hist])],
      :vertical
    )
  end

  defp build_main_jointplot(vl, data, :density_heatmap, fields) do
    heatmap_no_data(vl, data, fields, &density_heatmap_defaults/2)
  end

  defp build_main_jointplot(vl, data, mark, fields) do
    chart_no_data(vl, data, mark, fields)
  end

  defp build_marginal_jointplot(fields, opts) do
    {x, y} = {fields[:x][:field], fields[:y][:field]}

    xx = [type: :quantitative, bin: true, axis: nil]
    xy = [type: :quantitative, aggregate: :count, title: ""]

    x_root =
      if opts[:width], do: Vl.new(height: 60, width: opts[:width]), else: Vl.new(height: 60)

    y_root =
      if opts[:height], do: Vl.new(width: 60, height: opts[:height]), else: Vl.new(width: 60)

    x_hist =
      x_root
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, x, xx)
      |> Vl.encode_field(:y, x, xy)

    y_hist =
      y_root
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, y, xy)
      |> Vl.encode_field(:y, y, xx)

    {x_hist, y_hist}
  end

  ## Shared helpers

  defp encode_mark(vl, opts) when is_list(opts) do
    {mark, opts} = Keyword.pop!(opts, :type)
    Vl.mark(vl, mark, opts)
  end

  defp encode_mark(vl, mark) when is_atom(mark), do: Vl.mark(vl, mark)

  defp encode_fields(vl, fields, cols) do
    Enum.reduce(fields, vl, fn {field, opts}, acc ->
      {col, opts} = Keyword.pop!(opts, :field)
      opts = Keyword.put_new_lazy(opts, :type, fn -> cols[col] end)
      Vl.encode_field(acc, field, col, opts)
    end)
  end

  defp encode_layer(cols, mark, fields) do
    Vl.new() |> encode_mark(mark) |> encode_fields(fields, cols)
  end

  defp attach_data(vl, data, fields) do
    used_fields =
      fields
      |> Enum.flat_map(fn
        {:extra_fields, fields} -> List.wrap(fields)
        {_, field} when is_list(field) -> [field[:field]]
        {_, field} -> [field]
      end)
      |> Enum.uniq()

    Vl.data_from_values(vl, data, only: used_fields)
  end

  defp normalize_fields(fields, fun \\ fn _field, opts -> opts end) do
    for {field, opts} <- fields, field != :extra_fields do
      opts = if is_list(opts), do: fun.(field, opts), else: fun.(field, field: opts)
      {field, opts}
    end
  end

  @doc """
  Returns the specification of a polar plot grid.

  The returned specification contains extra config that's passed
  through to `polar_plot/4` for easier composability.

  See also: `polar_plot/4`

  ## Options

    * `:radius_marks` - optional list of values for the radius markings.
    * `:direction` - one of `:counter_clockwise` or `:clockwise`, which will affect the direction
      in which the angles grow from the starting point. Defaults to `:counter_clockwise`.
    * `:angle_marks` - list of angles for marking the grid. Defaults to `Enum.to_list(0..360//90)`.
    * `:angle_offset` - offset for the 0º reference. The sign will obey the `:direction` option. Defaults to `0`.
    * `:opacity` - opacity of the grid. Defaults to `1`.
    * `:color` - backround color for the grid. Defaults to `"white"`.
    * `:stroke_color` - stroke color for the grid markings. Defaults to `"black"`.
    * `:stroke_opacity` - opacity for the grid strokes. Defaults to `1`.

  ## Examples

  This first call will plot the grid using all default options.

      VegaLite.Data.polar_grid([0, 1, 2, 3, 4, 5])

  The second call is a more customized example, with custom angle offset, direction
  and angle markings:

      vl = VegaLite.new(title: "Polars", width: 500, height: 500)
      VegaLite.Data.polar_grid(vl, [0, 1, 2, 3, 4, 5], angle_offset: -90, direction: :clockwise)
  """
  def polar_grid(radius_marks, opts \\ []), do: polar_grid(Vl.new(), radius_marks, opts)

  def polar_grid(vl, radius_marks, opts) do
    opts =
      Keyword.validate!(
        opts,
        angle_marks: [0, 90, 180, 270, 360],
        direction: :counter_clockwise,
        angle_offset: 0,
        opacity: 1,
        color: "white",
        stroke_color: "black",
        stroke_opacity: 1
      )

    grid_layers = polar_angle_layers(opts)
    radius_layers = polar_radius_layers(radius_marks, opts)

    vl = append_layers(vl |> Vl.data_from_values(%{"_r" => [0]}), grid_layers ++ radius_layers)

    put_in(
      vl.spec["_vl_polar_config"],
      opts
      |> Keyword.take([:angle_offset, :direction])
      |> Map.new()
      |> Map.put(:radius_marks, radius_marks)
      |> Map.put(:hide_axes, true)
    )
  end

  @doc """
  Receives data represented in the polar domain and plots it into a grid.

  By default, the grid will be the usual cartesian grid, with the data converted
  into rectangular coordinates. If the given `VegaLite` spec was generated through
  `VegaLite.Data.polar_grid/3`, the cartesian grid will be hidden by default such
  that the resulting plot is purely in the polar domain.

  `data` contains data inside a container which supports the `Table.Reader` protocol.

  `mark` is either an atom for the mark type (usually `:point` or `:line`) or a keyword
  list containing the `:type` key specifying the mark type and any options for the mark.

  The `fields` argument must contain specifications for the `:r` and `:theta`,
  mapping them onto keys contained in `data`.

  It may also contain the following meta-fields:

    * `:x` - options for the x-axis
    * `:y` - options for the y-axis
    * `:legend` - the key which contains the legend field for grouping multiple plots.

  ## Examples

  In this first example, we plot a standalone cartesian plot.
  Note that we're configuring the X and Y axes of the plot through the `fields` argument.

      data = %{
        "r" => [1, 2, 3, 3, 4],
        "theta" => [0, 30, 45, 135, 270],
        "Group" => List.duplicate("First Line", 5)
      }

      VegaLite.Data.polar_plot(
        VegaLite.new(height: 500, width: 500),
        data,
        [type: :line, point: true, interpolate: :cardinal, color: "black"],
        r: "r",
        theta: "theta",
        x: [scale: [domain: [-5, 5]]],
        y: [scale: [domain: [-10, 3]]],
        legend: "Group"
      )

  In this second example, we plot data onto a polar grid. Note that we include include the points
  as separate layers for more customization.

      legend_key = "Line Groups"

      data = %{
        "r" => [1, 2, 3, 3, 4],
        "theta" => [0, 30, 45, 135, 270],
        legend_key => List.duplicate("First Line", 5)
      }

      other_data = %{
        "r" => [8, 6, 4, 2, 0],
        "theta" => [0, 30, 60, 90, 120],
        legend_key => List.duplicate("Second Line", 5)
      }

      list = [
        {data, type: :line, point: true, interpolate: "cardinal"},
        {data, :point},
        {other_data, type: :line, point: true, interpolate: "cardinal"},
        {other_data, type: :point, stroke: "black", stroke_width: 2, size: 100, shape: "triangle"}
      ]

      vl = VegaLite.new(title: "Polar Plot", height: 500, width: 500)
      vl_grid =  VegaLite.Data.polar_grid(vl, [0, 1, 2, 3, 4, 5, 7], angle_marks: [0, 15, 30, 45, 60, 90, 180, 270, 360])

      for {data, mark} <- list, reduce: vl_grid do
        v ->
          VegaLite.Data.polar_plot(v, data, mark, r: "r", theta: "theta", legend: legend_key)
      end
  """
  def polar_plot(vl \\ Vl.new(), data, mark, fields) do
    vl_polar_config =
      case vl.spec do
        %{"_vl_polar_config" => conf} ->
          Enum.to_list(conf)

        _ ->
          [radius_marks: nil, angle_offset: 0, direction: :counter_clockwise]
      end

    data_layer =
      polar_plot_data_layers(
        data,
        mark,
        fields,
        vl_polar_config
      )

    append_layers(vl, [data_layer])
  end

  defp append_layers(vl, layers) do
    layers = Enum.map(layers, &(&1 |> Vl.to_spec() |> Map.delete("$schema")))

    update_in(vl.spec, fn spec ->
      Map.update(spec, "layer", layers, &(&1 ++ layers))
    end)
  end

  defp deg_to_rad(angle), do: angle * :math.pi() / 180

  defp polar_angle_layers(opts) do
    angle_marks_input = opts[:angle_marks]
    angle_offset = opts[:angle_offset]

    {angle_marks, angle_marks2, angle_offset} =
      case opts[:direction] do
        :clockwise ->
          angle_marks = [0 | Enum.sort(angle_marks_input)]
          angle_marks2 = tl(angle_marks) ++ [360]

          {angle_marks, angle_marks2, angle_offset + 90}

        :counter_clockwise ->
          angle_marks = [360 | Enum.sort(angle_marks_input, :desc)]
          angle_marks2 = tl(angle_marks) ++ [0]

          {Enum.map(angle_marks, &(-&1)), Enum.map(angle_marks2, &(-&1)), -angle_offset + 90}
      end

    has_zero = 0 in angle_marks_input

    [angle_marks, angle_marks2]
    |> Enum.zip_with(fn [t, t2] ->
      is_360 = :math.fmod(t, 360) == 0

      label =
        if (t != 0 and not is_360) or (t == 0 and has_zero) or
             (is_360 and not has_zero) do
          Vl.new()
          |> Vl.mark(:text,
            text: to_string(abs(t)) <> "º",
            theta: "#{deg_to_rad(t + angle_offset)}",
            radius: [expr: "min(width, height) * 0.55"]
          )
        else
          []
        end

      theta = deg_to_rad(t + angle_offset)
      theta2 = deg_to_rad(t2 + angle_offset)

      [
        Vl.new()
        |> Vl.mark(:arc,
          theta: "#{theta}",
          theta2: "#{theta2}",
          stroke: opts[:stroke_color],
          stroke_opacity: opts[:stroke_opacity],
          opacity: opts[:opacity],
          color: opts[:color]
        ),
        label
      ]
    end)
    |> List.flatten()
  end

  defp polar_radius_layers(radius_marks, opts) do
    max_radius = Enum.max(radius_marks)

    radius_marks_vl =
      Enum.map(radius_marks, fn r ->
        Vl.mark(Vl.new(), :arc,
          radius: [expr: "#{r / max_radius} * min(width, height)/2"],
          radius2: [expr: "#{r / max_radius} * min(width, height)/2 + 1"],
          theta: "0",
          theta2: "#{2 * :math.pi()}",
          stroke_color: opts[:stroke_color],
          color: opts[:stroke_color],
          opacity: opts[:stroke_opacity]
        )
      end)

    radius_ruler_vl = [
      Vl.new()
      |> Vl.data_from_values(%{
        r: radius_marks,
        theta: Enum.map(radius_marks, fn _ -> :math.pi() / 4 end)
      })
      |> Vl.mark(:text,
        color: opts[:stroke_color],
        radius: [expr: "datum.r  * min(width, height) / (2 * #{max_radius})"],
        theta: :math.pi() / 2,
        dy: 10,
        dx: -10
      )
      |> Vl.encode_field(:text, "r", type: :quantitative)
    ]

    radius_marks_vl ++ radius_ruler_vl
  end

  defp polar_plot_data_layers(data, mark, fields, opts) do
    pi = :math.pi()
    legend_key = fields[:legend]

    {x_sign, y_sign} = if opts[:direction] == :counter_clockwise, do: {"-", "+"}, else: {"+", "-"}

    rotation = deg_to_rad(opts[:angle_offset])

    x_formula =
      "datum.x_linear * cos(#{rotation}) #{x_sign}datum.y_linear * sin(#{rotation})"

    y_formula =
      "#{y_sign}datum.x_linear * sin(#{rotation}) + datum.y_linear * cos(#{rotation})"

    r =
      case fields[:r] do
        opts when is_list(opts) -> opts[:field]
        field when is_binary(field) -> field
      end

    theta =
      case fields[:theta] do
        opts when is_list(opts) -> opts[:field]
        field when is_binary(field) -> field
      end

    auto_field_opts =
      if radius_marks = opts[:radius_marks] do
        max_radius = Enum.max(radius_marks)

        [
          scale: [
            domain: [-max_radius, max_radius]
          ],
          axis: [
            grid: false,
            ticks: false,
            domain_opacity: 0,
            labels: false,
            title: false,
            domain: false,
            offset: 50
          ]
        ]
      else
        []
      end

    get_field_opts = fn field ->
      if opts[:hide_axes] do
        [type: :quantitative]
        |> Keyword.merge(fields[field] || [])
        |> Keyword.merge(auto_field_opts)
      else
        Keyword.merge([type: :quantitative], fields[field] || [])
      end
    end

    data_fields = if legend_key, do: [r, theta, legend_key], else: [r, theta]

    auto_tooltip =
      Enum.map(data, fn
        {^legend_key, _} ->
          [field: to_string(legend_key), type: :nominal]

        {field, _} ->
          [field: to_string(field), type: :quantitative]
      end)

    x_opts = get_field_opts.(:x)
    y_opts = get_field_opts.(:y)

    tooltip =
      if opts[:radius_marks] do
        auto_tooltip
      else
        auto_tooltip ++ [[field: "x", type: x_opts[:type]], [field: "y", type: y_opts[:type]]]
      end

    Vl.new()
    |> Vl.data_from_values(data, only: data_fields)
    |> Vl.transform(calculate: "datum.#{r} * cos(datum.#{theta} * #{pi / 180})", as: "x_linear")
    |> Vl.transform(
      calculate: "datum.#{r} * sin(#{y_sign}datum.#{theta} * #{pi / 180})",
      as: "y_linear"
    )
    |> Vl.transform(calculate: x_formula, as: "x")
    |> Vl.transform(calculate: y_formula, as: "y")
    |> encode_mark(mark)
    |> then(fn vl ->
      if legend_key do
        Vl.encode_field(vl, :color, legend_key,
          type: :nominal,
          scale: Keyword.take(opts, [:scheme])
        )
      else
        vl
      end
    end)
    |> Vl.encode_field(:x, "x", x_opts)
    |> Vl.encode_field(:y, "y", y_opts)
    |> Vl.encode_field(:order, "theta")
    |> Vl.encode(:tooltip, tooltip)
  end

  ## Infer types

  @doc """
  Returns a map with each column and its respective inferred type for the given data.
  """
  @spec columns_for(Table.Reader.t()) :: map() | nil
  def columns_for(data) do
    with true <- implements?(Table.Reader, data),
         data = {_, %{columns: [_ | _] = columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      types = infer_types(data)
      Enum.zip_with(columns, types, fn column, type -> {to_string(column), type} end) |> Map.new()
    else
      _ -> nil
    end
  end

  defp implements?(protocol, value), do: protocol.impl_for(value) != nil

  defp infer_types({:columns, %{columns: _columns}, data}) do
    Enum.map(data, fn data -> data |> Enum.at(0) |> type_of() end)
  end

  defp infer_types({:rows, %{columns: columns}, data}) do
    case Enum.fetch(data, 0) do
      {:ok, row} -> Enum.map(row, &type_of/1)
      :error -> Enum.map(columns, fn _ -> nil end)
    end
  end

  defp type_of(%mod{}) when mod in [Decimal], do: :quantitative
  defp type_of(%mod{}) when mod in [Date, NaiveDateTime, DateTime], do: :temporal

  defp type_of(data) when is_number(data), do: :quantitative

  defp type_of(data) when is_binary(data) do
    if date?(data) or date_time?(data), do: :temporal, else: :nominal
  end

  defp type_of(data) when is_atom(data), do: :nominal

  defp type_of(_), do: nil

  defp date?(value), do: match?({:ok, _}, Date.from_iso8601(value))
  defp date_time?(value), do: match?({:ok, _, _}, DateTime.from_iso8601(value))
end
