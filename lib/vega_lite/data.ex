defmodule VegaLite.Data do
  @moduledoc """
  Data is a VegaLite module designed to provide a shorthand API for charts based on data.

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
    vl
    |> encode_fields(normalize_fields(fields), columns_for(data))
    |> attach_data(data, fields)
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
    vl
    |> encode_mark(mark)
    |> encode_fields(normalize_fields(fields), columns_for(data))
    |> attach_data(data, fields)
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
