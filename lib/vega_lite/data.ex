defmodule VegaLite.Data do
  alias VegaLite, as: Vl

  def chart([data | opts], mark, fields), do: chart(Vl.new(opts), data, mark, fields)
  def chart(data, mark, fields), do: chart(Vl.new(), data, mark, fields)

  def chart(vl, data, mark, fields) do
    cols = columns_for(data)
    used_fields = fields |> Keyword.values() |> used_fields()
    root = vl |> Vl.data_from_values(data, only: used_fields) |> enconde_mark(mark)

    for {field, col} <- fields, reduce: root do
      acc -> encode_field(acc, cols, field, col)
    end
  end

  def heatmap([data | opts], fields), do: heatmap(Vl.new(opts), data, fields)
  def heatmap(data, fields), do: heatmap(Vl.new(), data, fields)

  def heatmap(vl, data, fields) do
    fields = Enum.map(fields, &heatmap_defaults/1)

    if fields[:text],
      do: annotated_heatmap(vl, data, fields),
      else: chart(vl, data, :rect, fields)
  end

  defp annotated_heatmap(vl, data, fields) do
    text = fields[:text]
    fields = List.keydelete(fields, :text, 0)

    vl
    |> Vl.layers([
      chart(data, :rect, fields),
      chart(data, :text, text: text, x: fields[:x], y: fields[:y])
    ])
  end

  defp heatmap_defaults({field, [col | opts]}) when field in [:x, :y] do
    opts = Keyword.put_new(opts, :type, :nominal)
    {field, List.flatten([col, opts])}
  end

  defp heatmap_defaults({field, col}) when field in [:x, :y] do
    {field, [col, type: :nominal]}
  end

  defp heatmap_defaults({field, [col | opts]}) when field in [:color, :text] do
    opts = Keyword.put_new(opts, :type, :quantitative)
    {field, List.flatten([col, opts])}
  end

  defp heatmap_defaults({field, col}) when field in [:color, :text] do
    {field, [col, type: :quantitative]}
  end

  defp enconde_mark(vl, [mark | opts]), do: Vl.mark(vl, mark, opts)
  defp enconde_mark(vl, mark), do: Vl.mark(vl, mark)

  defp encode_field(schema, cols, field, [col | opts]) do
    opts = Keyword.put_new(opts, :type, type_for(cols, col))
    Vl.encode_field(schema, field, col, opts)
  end

  defp encode_field(schema, cols, field, col) do
    Vl.encode_field(schema, field, col, type: type_for(cols, col))
  end

  defp used_fields(fields) do
    for field <- fields, field, uniq: true do
      if is_list(field), do: hd(field), else: field
    end
  end

  defp type_for(data, name) do
    get_in(data, [Access.filter(&(&1.name == name)), :type])
    |> hd()
    |> String.to_atom()
  end

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

  defp type_of(%mod{}) when mod in [Decimal], do: "quantitative"
  defp type_of(%mod{}) when mod in [Date, NaiveDateTime, DateTime], do: "temporal"

  defp type_of(data) when is_number(data), do: "quantitative"

  defp type_of(data) when is_binary(data) do
    if date?(data) or date_time?(data), do: "temporal", else: "nominal"
  end

  defp type_of(data) when is_atom(data), do: "nominal"

  defp type_of(_), do: nil

  defp date?(value), do: match?({:ok, _}, Date.from_iso8601(value))
  defp date_time?(value), do: match?({:ok, _, _}, DateTime.from_iso8601(value))
end
