defmodule VegaLite.ExportTest do
  use ExUnit.Case

  alias VegaLite, as: Vl
  alias VegaLite.Export

  @data [
    %{"height" => 170, "weight" => 80, "width" => 10, "unused" => "a"},
    %{"height" => 190, "weight" => 85, "width" => 20, "unused" => "b"}
  ]

  describe "to_json/2" do
    test "should return the spec as VegaLite formatted JSON" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert Export.to_json(vl) =~ "https://vega.github.io/schema/vega-lite/v5.json"
    end

    test "should return the spec as Vega formatted JSON" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert Export.to_json(vl, target: :vega) =~ "https://vega.github.io/schema/vega/v5.json"
    end
  end
end
