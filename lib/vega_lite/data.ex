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
  """
  def chart(data, fields), do: chart(Vl.new(), data, fields)

  @doc """
  Returns the specification for the given arguments.

  It can takes a data, a mark and a list of fields to be encoded or
  a valid `VegaLite` specification, a data and a list of fields to be encoded.

  Each argument that is not a `VegaLite` specification nor a data, is accepted as the argument
  itself or a keyword list of options. All options must follow the specifications of the
  `VegaLite` module.

  ## Examples

      data = [
        %{"category" => "A", "score" => 28},
        %{"category" => "B", "score" => 55}
      ]

      Data.chart(data, :bar, x: "category", y: "score")

      Vl.new()
      |> Vl.mark(:bar)
      |> Data.chart(data, x: "category", y: "score")

      Data.chart(data, x: "category", y: "score")
      |> Vl.mark(:bar)

  The above examples achieves the same results as the example below.

      Vl.new()
      |> Vl.data_from_values(data, only: ["category", "score"])
      |> Vl.mark(:bar)
      |> Vl.encode_field(:x, "category", type: :nominal)
      |> Vl.encode_field(:y, "score", type: :quantitative)
  """
  def chart(%Vl{} = vl, data, fields) do
    cols = columns_for(data)
    used_fields = fields |> Keyword.values() |> used_fields()
    root = vl |> Vl.data_from_values(data, only: used_fields)
    build_fields(fields, root, cols)
  end

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
    root = vl |> Vl.data_from_values(data, only: used_fields) |> encode_mark(mark)
    build_fields(fields, root, cols)
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
    fields = standardize_fields(fields) |> Enum.map(&heatmap_defaults/1)

    if fields[:text],
      do: annotated_heatmap(vl, data, fields),
      else: chart(vl, data, :rect, fields)
  end

  defp annotated_heatmap(vl, data, fields) do
    text_fields = [text: fields[:text], x: fields[:x], y: fields[:y]]
    fields = Keyword.delete(fields, :text)
    used_fields = fields |> Keyword.values() |> used_fields()

    vl
    |> Vl.data_from_values(data, only: used_fields)
    |> Vl.layers([layer(data, :rect, fields), layer(data, :text, text_fields)])
  end

  defp heatmap_defaults({field, opts}) when field in [:x, :y] do
    {field, Keyword.put_new(opts, :type, :nominal)}
  end

  defp heatmap_defaults({field, opts}) when field in [:color, :text] do
    {field, Keyword.put_new(opts, :type, :quantitative)}
  end

  defp encode_mark(vl, opts) when is_list(opts) do
    {mark, opts} = Keyword.pop!(opts, :type)
    Vl.mark(vl, mark, opts)
  end

  defp encode_mark(vl, mark), do: Vl.mark(vl, mark)

  defp encode_field(schema, cols, field, opts) do
    {col, opts} = Keyword.pop!(opts, :field)
    opts = Keyword.put_new_lazy(opts, :type, fn -> cols[col] end)
    Vl.encode_field(schema, field, col, opts)
  end

  defp layer(data, mark, fields) do
    cols = columns_for(data)
    root = Vl.new() |> encode_mark(mark)
    build_fields(fields, root, cols)
  end

  defp used_fields(fields) do
    for field <- fields, field, uniq: true do
      if is_list(field), do: field[:field], else: field
    end
  end

  defp build_fields(fields, root, cols) do
    fields
    |> standardize_fields()
    |> Enum.reduce(root, fn {field, opts}, acc -> encode_field(acc, cols, field, opts) end)
  end

  defp standardize_fields(fields) do
    for {field, opts} <- fields do
      if is_list(opts), do: {field, opts}, else: {field, [field: opts]}
    end
  end

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
