defmodule VegaLite.Data do
  @moduledoc """
  Data is a VegaLite module designed to provide a shorthand API for commonly used charts and
  high-level abstractions for specialized plots.

  Optionally accepts and always returns a valid `VegaLite` spec, fostering flexibility to be used
  alone or in combination with the `VegaLite` module at any level and at any point.

  It relies on internal type inference, and although all options can be overridden,
  only data that implements the [Table.Reader](https://hexdocs.pm/table/Table.Reader.html)
  protocol is supported.
  """

  alias VegaLite, as: Vl

  @doc """
  Returns the specification for a given data and a list of fields to be encoded.

  See `chart/3`.
  """
  @spec chart(Table.Reader.t(), keyword()) :: VegaLite.t()
  def chart(data, fields), do: chart(Vl.new(), data, fields)

  @doc """
  Returns the specification for the a given data, a mark and a list of fields to be encoded.

  Uses a subset of the used fields from the data by default.
  More fields can be added using the `:extra_fields` option.

  Each argument that is not a `VegaLite` specification nor a data is accepted as the argument
  itself or a keyword list of options. All options must follow the specifications of the
  `VegaLite` module, except `:extra_fields`.

  # Specific options

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
  """
  @spec chart(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def chart(%Vl{} = vl, data, fields) do
    {cols, fields, used_fields} = build_options(data, fields)
    root = vl |> Vl.data_from_values(data, only: used_fields)
    encode_fields(fields, root, cols)
  end

  @spec chart(Table.Reader.t(), atom() | keyword(), keyword()) :: VegaLite.t()
  def chart(data, mark, fields), do: chart(Vl.new(), data, mark, fields)

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
    {cols, fields, used_fields} = build_options(data, fields)
    root = vl |> Vl.data_from_values(data, only: used_fields) |> encode_mark(mark)
    encode_fields(fields, root, cols)
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

  """
  @spec heatmap(Table.Reader.t(), keyword()) :: VegaLite.t()
  def heatmap(data, fields), do: heatmap(Vl.new(), data, fields)

  @doc """
  Same as heatmap/2, but takes a valid `VegaLite` specification as the first argument.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Vl.new(title: "Heatmap", width: 500)
      |> Data.heatmap(data, x: "category", y: "score", color: "score", text: "category")
  """
  @spec heatmap(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def heatmap(vl, data, fields) do
    for key <- [:x, :y], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a heatmap"
    end

    opts = build_options(data, fields, &heatmap_defaults/2)
    build_heatmap_layers(vl, data, opts)
  end

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

  """
  @spec density_heatmap(Table.Reader.t(), keyword()) :: VegaLite.t()
  def density_heatmap(data, fields), do: density_heatmap(Vl.new(), data, fields)

  @doc """
  Same as density_heatmap/2, but takes a valid `VegaLite` specification as the first argument.

  ## Examples

      data = [
        %{"total_bill" => 16.99, "tip" => 1.0},
        %{"total_bill" => 10.34, "tip" => 1.66}
      ]

      Vl.new(title: "Density Heatmap", width: 500)
      |> Data.heatmap(data, x: "total_bill", y: "tip", color: "total_bill", text: "tip")
  """
  @spec density_heatmap(VegaLite.t(), Table.Reader.t(), keyword()) :: VegaLite.t()
  def density_heatmap(vl, data, fields) do
    for key <- [:x, :y, :color], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a density heatmap"
    end

    opts = build_options(data, fields, &density_heatmap_defaults/2)
    build_heatmap_layers(vl, data, opts)
  end

  def joint_plot(data, fields), do: joint_plot(Vl.new(), data, fields)

  def joint_plot(vl, data, fields) do
    for key <- [:x, :y], is_nil(fields[key]) do
      raise ArgumentError, "the #{key} field is required to plot a jointplot"
    end

    {kind, fields} = Keyword.pop(fields, :kind, :circle)

    {_cols, fields, used_fields} = build_options(data, fields)

    marginals = build_marginal_jointplot(data, fields)
    main_chart = build_main_jointplot(data, kind, fields)

    build_jointplot(vl, data, used_fields, main_chart, marginals)
  end

  ## Specialized defaults

  defp heatmap_defaults(field, opts) when field in [:x, :y] do
    Keyword.put_new(opts, :type, :nominal)
  end

  defp heatmap_defaults(field, opts) when field in [:color, :text] do
    Keyword.put_new(opts, :type, :quantitative)
  end

  defp heatmap_defaults(_field, opts) do
    opts
  end

  defp density_heatmap_defaults(field, opts) when field in [:x, :y] do
    opts |> Keyword.put_new(:type, :quantitative) |> Keyword.put_new(:bin, true)
  end

  defp density_heatmap_defaults(field, opts) when field in [:color, :text] do
    opts |> Keyword.put_new(:type, :quantitative) |> Keyword.put_new(:aggregate, :count)
  end

  defp density_heatmap_defaults(_field, opts) do
    opts
  end

  ## Shared helpers

  defp encode_mark(vl, opts) when is_list(opts) do
    {mark, opts} = Keyword.pop!(opts, :type)
    Vl.mark(vl, mark, opts)
  end

  defp encode_mark(vl, mark) when is_atom(mark), do: Vl.mark(vl, mark)

  defp encode_fields(fields, root, cols) do
    Enum.reduce(fields, root, fn {field, opts}, acc -> encode_field(acc, cols, field, opts) end)
  end

  defp encode_field(schema, cols, field, opts) do
    {col, opts} = Keyword.pop!(opts, :field)
    opts = Keyword.put_new_lazy(opts, :type, fn -> cols[col] end)
    Vl.encode_field(schema, field, col, opts)
  end

  defp encode_layer(cols, mark, fields) do
    root = Vl.new() |> encode_mark(mark)
    encode_fields(fields, root, cols)
  end

  defp build_options(data, fields, fun \\ fn _field, opts -> opts end) do
    {extra_fields, fields} = Keyword.pop(fields, :extra_fields)
    used_fields = Enum.uniq(used_fields(fields) ++ List.wrap(extra_fields))
    {columns_for(data), standardize_fields(fields, fun), used_fields}
  end

  defp build_heatmap_layers(vl, data, {cols, fields, used_fields}) do
    text_fields = Keyword.take(fields, [:text, :x, :y])
    rect_fields = Keyword.delete(fields, :text)

    layers =
      [encode_layer(cols, :rect, rect_fields)] ++
        if fields[:text] do
          [encode_layer(cols, :text, text_fields)]
        else
          []
        end

    vl
    |> Vl.data_from_values(data, only: used_fields)
    |> Vl.layers(layers)
  end

  defp build_jointplot(vl, data, used_fields, main_chart, {x_hist, y_hist}) do
    vl
    |> Vl.data_from_values(data, only: used_fields)
    |> Vl.concat([x_hist, Vl.new() |> Vl.concat([main_chart, y_hist])], :vertical)
  end

  defp build_main_jointplot(data, :density_heatmap, fields) do
    density_heatmap(data, fields) |> Map.update!(:spec, &Map.delete(&1, "data"))
  end

  defp build_main_jointplot(data, mark, fields) do
    chart(data, mark, fields) |> Map.update!(:spec, &Map.delete(&1, "data"))
  end

  defp build_marginal_jointplot(data, fields) do
    {x, y} = {fields[:x], fields[:y]}

    xx = [bin: true, axis: nil]
    xy = [aggregate: :count, title: ""]

    x_hist =
      Vl.new(height: 60)
      |> chart(data, :bar, x: x ++ xx, y: x ++ xy)
      |> Map.update!(:spec, &Map.delete(&1, "data"))

    y_hist =
      Vl.new(width: 60)
      |> chart(data, :bar, x: y ++ xy, y: y ++ xx)
      |> Map.update!(:spec, &Map.delete(&1, "data"))

    {x_hist, y_hist}
  end

  defp used_fields(fields) do
    for {_key, field} <- fields do
      if is_list(field), do: field[:field], else: field
    end
  end

  defp standardize_fields(fields, fun) do
    for {field, opts} <- fields do
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
