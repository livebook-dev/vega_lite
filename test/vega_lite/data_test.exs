defmodule VegaLite.DataTest do
  use ExUnit.Case

  alias VegaLite.Data
  alias VegaLite, as: Vl

  @data [%{"height" => 170, "weight" => 80}, %{"height" => 190, "weight" => 85}]

  describe "shorthand api" do
    test "single field" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Data.chart(@data, :bar, x: "height")
    end

    test "multiple fields" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:y, "weight", type: :quantitative)

      assert vl == Data.chart(@data, :bar, x: "height", y: "weight")
    end

    test "mark with options" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point, line: true)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Data.chart(@data, {:point, line: true}, x: "height")
    end

    test "root with options" do
      vl =
        Vl.new(title: "With title")
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Data.chart({@data, title: "With title"}, :point, x: "height")
    end

    test "single field with options" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :nominal)

      assert vl == Data.chart(@data, :bar, x: {"height", type: :nominal})
    end

    test "multiple fields with options" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :nominal)
        |> Vl.encode_field(:y, "weight", type: :nominal)

      assert vl ==
               Data.chart(@data, :bar,
                 x: {"height", type: :nominal},
                 y: {"weight", type: :nominal}
               )
    end

    test "multiple root options" do
      vl =
        Vl.new(title: "With title", width: 300)
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Data.chart({@data, title: "With title", width: 300}, :point, x: "height")
    end

    test "nested field options" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "height", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Data.chart(@data, :bar,
                 x: "height",
                 color: {"height", type: :quantitative, scale: [scheme: "category10"]}
               )
    end

    test "multiple and nested field and root options" do
      vl =
        Vl.new(title: "With title", width: 300)
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "height", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Data.chart({@data, title: "With title", width: 300}, :bar,
                 x: "height",
                 color: {"height", type: :quantitative, scale: [scheme: "category10"]}
               )
    end

    test "piped from VegaLite" do
      vl =
        Vl.new(title: "With title")
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Vl.new(title: "With title") |> Data.chart(@data, :point, x: "height")
    end

    test "piped into VegaLite" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "height", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Data.chart(@data, :point, x: "height")
               |> Vl.encode_field(:color, "height",
                 type: :quantitative,
                 scale: [scheme: "category10"]
               )
    end

    test "piped from and into VegaLite" do
      vl =
        Vl.new(title: "With title")
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "height", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Vl.new(title: "With title")
               |> Data.chart(@data, :point, x: "height")
               |> Vl.encode_field(:color, "height",
                 type: :quantitative,
                 scale: [scheme: "category10"]
               )
    end

    test "combined with layers" do
      vl =
        Vl.new(title: "Heatmap")
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      sh =
        Vl.new(title: "Heatmap")
        |> Vl.layers([
          Data.chart(@data, :rect,
            x: {"height", type: :nominal},
            y: {"weight", type: :nominal},
            color: "height"
          ),
          Data.chart(@data, :text,
            x: {"height", type: :nominal},
            y: {"weight", type: :nominal},
            text: "height"
          )
        ])

      assert vl == sh
    end
  end

  describe "heatmap" do
    test "simple heatmap" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data)
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "height", type: :nominal)
        |> Vl.encode_field(:y, "weight", type: :nominal)

      assert vl == Data.heatmap(@data, x: "height", y: "weight")
    end

    test "simple heatmap with color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data)
        |> Vl.mark(:rect)
        |> Vl.encode_field(:x, "height", type: :nominal)
        |> Vl.encode_field(:y, "weight", type: :nominal)
        |> Vl.encode_field(:color, "height", type: :quantitative)

      assert vl == Data.heatmap(@data, x: "height", y: "weight", color: "height")
    end

    test "heatmap with color and text" do
      vl =
        Vl.new()
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl == Data.heatmap(@data, x: "height", y: "weight", color: "height", text: "height")
    end

    test "heatmap with title" do
      vl =
        Vl.new(title: "Heatmap")
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl ==
               Data.heatmap({@data, title: "Heatmap"},
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height"
               )
    end

    test "heatmap with specified types" do
      vl =
        Vl.new()
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative)
          |> Vl.encode_field(:y, "weight", type: :quantitative)
          |> Vl.encode_field(:color, "height", type: :nominal),
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative)
          |> Vl.encode_field(:y, "weight", type: :quantitative)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl ==
               Data.heatmap(@data,
                 x: {"height", type: :quantitative},
                 y: {"weight", type: :quantitative},
                 color: {"height", type: :nominal},
                 text: "height"
               )
    end

    test "heatmap with a Vl spec" do
      vl =
        Vl.new(title: "Heatmap", width: 500)
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.data_from_values(@data)
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl ==
               Vl.new(title: "Heatmap", width: 500)
               |> Data.heatmap(@data, x: "height", y: "weight", color: "height", text: "height")
    end
  end
end
