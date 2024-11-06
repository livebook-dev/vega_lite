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
      vl = generate_vl()

      assert Export.to_json(vl) =~ "https://vega.github.io/schema/vega-lite/v5.json"
    end

    test "should return the spec as Vega formatted JSON" do
      vl = generate_vl()

      assert Export.to_json(vl, target: :vega) =~ "https://vega.github.io/schema/vega/v5.json"
    end
  end

  describe "to_html/2" do
    test "should return an HTML document with the visual as an SVG with the JS bundled by default" do
      vl = generate_vl()
      html = Export.to_html(vl)

      assert html =~ "{\"renderer\":\"svg\"}"
      refute html =~ "https://cdn.jsdelivr.net/npm/vega-lite@5.20"
    end

    test "should return an HTML document with the visual as an SVG without the JS bundled" do
      vl = generate_vl()
      html = Export.to_html(vl, bundle: false)

      assert html =~ "{\"renderer\":\"svg\"}"
      assert html =~ "https://cdn.jsdelivr.net/npm/vega-lite@5.20"
    end

    test "should return an HTML document with the visual as a Canvas with the JS bundled" do
      vl = generate_vl()
      html = Export.to_html(vl, renderer: :canvas, bundle: true)

      refute html =~ "https://cdn.jsdelivr.net/npm/vega-lite@5.20"
      assert html =~ "{\"renderer\":\"canvas\"}"
    end

    test "should return an HTML document with the visual as a Canvas without the JS bundled" do
      vl = generate_vl()
      html = Export.to_html(vl, renderer: :canvas, bundle: false)

      assert html =~ "https://cdn.jsdelivr.net/npm/vega-lite@5.20"
      assert html =~ "{\"renderer\":\"canvas\"}"
    end
  end

  defp generate_vl do
    Vl.new()
    |> Vl.data_from_values(@data, only: ["height"])
    |> Vl.mark(:bar)
    |> Vl.encode_field(:x, "height", type: :quantitative)
  end
end
