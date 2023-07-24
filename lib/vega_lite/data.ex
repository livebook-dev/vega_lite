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
  Returns the specification for a given data, a mark and a list of fields to be encoded.

  Each argument is accepted as the argument itself or a tuple with the argument and a keyword
  list of options. All options must follow the specifications of the `VegaLite` module.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Data.chart(data, :bar, x: "category", y: "score")

  The above example achieves the same results as the example below.

      Vl.new()
      |> Vl.data_from_values(data, only: ["category", "score"])
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, "category", type: :nominal)
      |> Vl.encode_field(:y, "score", type: :quantitative)
  """
  def chart({data, opts}, mark, fields), do: chart(Vl.new(opts), data, mark, fields)
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

  The above example achieves the same results as the example below.

      Vl.new(title: "With title")
      |> Vl.data_from_values(data, only: ["category", "score"])
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, "category", type: :nominal)
      |> Vl.encode_field(:y, "score", type: :quantitative)
  """
  def chart(vl, data, mark, fields) do
    cols = columns_for(data)
    used_fields = fields |> Keyword.values() |> used_fields()
    root = vl |> Vl.data_from_values(data, only: used_fields) |> enconde_mark(mark)

    for {field, col} <- fields, reduce: root do
      acc -> encode_field(acc, cols, field, col)
    end
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

      Data.heatmap(data, x: "category", y: "score")

      Data.heatmap({data, title: "Heatmap"}, x: "category", y: "score")

      Data.heatmap(data, x: "category", y: "score", color: "score", text: "category")

  """
  def heatmap({data, opts}, fields), do: heatmap(Vl.new(opts), data, fields)
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
  def heatmap(vl, data, fields) do
    fields = Enum.map(fields, &heatmap_defaults/1)

    if fields[:text],
      do: annotated_heatmap(vl, data, fields),
      else: chart(vl, data, :rect, fields)
  end

  defp annotated_heatmap(vl, data, fields) do
    text_fields = [text: fields[:text], x: fields[:x], y: fields[:y]]
    fields = List.keydelete(fields, :text, 0)
    Vl.layers(vl, [chart(data, :rect, fields), chart(data, :text, text_fields)])
  end

  defp heatmap_defaults({field, {col, opts}}) when field in [:x, :y] do
    opts = Keyword.put_new(opts, :type, :nominal)
    {field, {col, opts}}
  end

  defp heatmap_defaults({field, col}) when field in [:x, :y] do
    {field, {col, type: :nominal}}
  end

  defp heatmap_defaults({field, {col, opts}}) when field in [:color, :text] do
    opts = Keyword.put_new(opts, :type, :quantitative)
    {field, {col, opts}}
  end

  defp heatmap_defaults({field, col}) when field in [:color, :text] do
    {field, {col, type: :quantitative}}
  end

  defp enconde_mark(vl, {mark, opts}), do: Vl.mark(vl, mark, opts)
  defp enconde_mark(vl, mark), do: Vl.mark(vl, mark)

  defp encode_field(schema, cols, field, {col, opts}) do
    opts = Keyword.put_new(opts, :type, type_for(cols, col))
    Vl.encode_field(schema, field, col, opts)
  end

  defp encode_field(schema, cols, field, col) do
    Vl.encode_field(schema, field, col, type: type_for(cols, col))
  end

  defp used_fields(fields) do
    for field <- fields, field, uniq: true do
      if is_tuple(field), do: elem(field, 0), else: field
    end
  end

  defp type_for(data, name), do: get_in(data, [Access.filter(&(&1.name == name)), :type]) |> hd()

  defp columns_for(data) do
    with true <- implements?(Table.Reader, data),
         data = {_, %{columns: [_ | _] = columns}, _} <- Table.Reader.init(data),
         true <- Enum.all?(columns, &implements?(String.Chars, &1)) do
      types = infer_types(data)
      Enum.zip_with(columns, types, fn column, type -> %{name: to_string(column), type: type} end)
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
