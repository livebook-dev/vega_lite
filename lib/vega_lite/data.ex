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

  As a specialized chart, the heatmap expects an `:x` and `:y` and optionally a `:color` and a
  `:text` field. Defaults to `:nominal` for the axes and `:quantitative` for color and text if
  types are not specified.

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
    text_fields = Keyword.take(fields, [:text, :x, :y])
    rect_fields = Keyword.delete(fields, :text)

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
  optionally a `:text` field. All data must be `:quantitative` and the default aggregation
  function is `:count`.

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
  `:text` field. All data must be `:quantitative` and the default `:kind` is `:circle`.

  It also accepts the specialized `:density_heatmap` as `:kind`.

  All customizations apply to the main chart only. The marginal histograms are not customizable.

  ## Examples

      data = [
        %{"total_bill" => 16.99, "tip" => 1.0},
        %{"total_bill" => 10.34, "tip" => 1.66}
      ]

      Data.joint_plot(data, x: "total_bill", y: "tip", kind: :bar)

  With an existing VegaLite spec:

      Vl.new(title: "Joint Plot", width: 500)
      |> Data.joint_plot(data, x: "total_bill", y: "tip", color: "total_bill")
  """
  @spec joint_plot(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def joint_plot(vl \\ Vl.new(), data, fields) do
    for key <- [:x, :y], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a jointplot"
    end

    root_opts =
      Enum.filter([width: vl.spec["width"], height: vl.spec["height"]], fn {_k, v} -> v end)

    {kind, fields} = Keyword.pop(fields, :kind, :circle)
    main_chart = build_main_jointplot(Vl.new(root_opts), data, kind, fields)
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

  ## Infer types

  defp columns_for(data) do
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
