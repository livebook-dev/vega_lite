defmodule VegaLiteTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  test "encode_field/4" do
    parsed_plot =
      Vl.from_json("""
      {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "encoding": {
          "x": {"field": "x", "type": "quantitative"}
        }
      }
      """)

    plot = Vl.new() |> Vl.encode_field(:x, "x", type: :quantitative)

    assert parsed_plot == plot
  end
end
