defmodule VegaLite.DataTest do
  use ExUnit.Case

  alias VegaLite.Data
  alias VegaLite, as: Vl

  @data [
    %{"height" => 170, "weight" => 80, "width" => 10, "unused" => "a"},
    %{"height" => 190, "weight" => 85, "width" => 20, "unused" => "b"}
  ]

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

      assert vl == Data.chart(@data, [type: :point, line: true], x: "height")
    end

    test "mark from pipe" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:point, line: true)
        |> Vl.encode_field(:x, "height", type: :quantitative)

      assert vl == Vl.new() |> Vl.mark(:point, line: true) |> Data.chart(@data, x: "height")
    end

    test "pipe to mark" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.mark(:point, line: true)

      assert vl == Vl.new() |> Data.chart(@data, x: "height") |> Vl.mark(:point, line: true)
    end

    test "single field with options" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height"])
        |> Vl.mark(:bar)
        |> Vl.encode_field(:x, "height", type: :nominal)

      assert vl == Data.chart(@data, :bar, x: [field: "height", type: :nominal])
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
                 x: [field: "height", type: :nominal],
                 y: [field: "weight", type: :nominal]
               )
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
                 color: [field: "height", type: :quantitative, scale: [scheme: "category10"]]
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

    test "piped into VegaLite with extra fields" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "weight", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Data.chart(@data, :point, x: "height", extra_fields: ["weight"])
               |> Vl.encode_field(:color, "weight",
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

    test "piped from and into VegaLite with extra fields" do
      vl =
        Vl.new(title: "With title")
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.mark(:point)
        |> Vl.encode_field(:x, "height", type: :quantitative)
        |> Vl.encode_field(:color, "weight", type: :quantitative, scale: [scheme: "category10"])

      assert vl ==
               Vl.new(title: "With title")
               |> Data.chart(@data, :point, x: "height", extra_fields: ["weight"])
               |> Vl.encode_field(:color, "weight",
                 type: :quantitative,
                 scale: [scheme: "category10"]
               )
    end

    test "combined with layers" do
      vl =
        Vl.new(title: "Heatmap")
        |> Vl.layers([
          Vl.new()
          |> Vl.data_from_values(@data, only: ["height", "weight"])
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.data_from_values(@data, only: ["height", "weight"])
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      sh =
        Vl.new(title: "Heatmap")
        |> Vl.layers([
          Data.chart(@data, :rect,
            x: [field: "height", type: :nominal],
            y: [field: "weight", type: :nominal],
            color: "height"
          ),
          Data.chart(@data, :text,
            x: [field: "height", type: :nominal],
            y: [field: "weight", type: :nominal],
            text: "height"
          )
        ])

      assert vl == sh
    end
  end

  describe "heatmap" do
    test "simple" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
        ])

      assert vl == Data.heatmap(@data, x: "height", y: "weight")
    end

    test "with color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative)
        ])

      assert vl == Data.heatmap(@data, x: "height", y: "weight", color: "height")
    end

    test "with text and color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl == Data.heatmap(@data, x: "height", y: "weight", color: "height", text: "height")
    end

    test "with text_color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
          |> Vl.encode_field(:color, "height", type: :quantitative)
        ])

      assert vl ==
               Data.heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height",
                 text_color: "height"
               )
    end

    test "with text_color with condition" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
          |> Vl.encode_field(:color, "height",
            type: :quantitative,
            condition: [
              [test: "datum['height'] < 0", value: :white],
              [test: "datum['height'] >= 0", value: :black]
            ]
          )
        ])

      assert vl ==
               Data.heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height",
                 text_color: [
                   field: "height",
                   condition: [
                     [test: "datum['height'] < 0", value: :white],
                     [test: "datum['height'] >= 0", value: :black]
                   ]
                 ]
               )
    end

    test "with title and extra fields" do
      vl =
        Vl.new(title: "Heatmap")
        |> Vl.data_from_values(@data, only: ["height", "weight", "width"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl ==
               Vl.new(title: "Heatmap")
               |> Data.heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height",
                 extra_fields: ["width"]
               )
    end

    test "with specified types" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative)
          |> Vl.encode_field(:y, "weight", type: :quantitative)
          |> Vl.encode_field(:color, "height", type: :nominal),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative)
          |> Vl.encode_field(:y, "weight", type: :quantitative)
          |> Vl.encode_field(:text, "height", type: :quantitative)
        ])

      assert vl ==
               Data.heatmap(@data,
                 x: [field: "height", type: :quantitative],
                 y: [field: "weight", type: :quantitative],
                 color: [field: "height", type: :nominal],
                 text: "height"
               )
    end

    test "with a text field different from the axes" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight", "width"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:color, "height", type: :quantitative),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :nominal)
          |> Vl.encode_field(:y, "weight", type: :nominal)
          |> Vl.encode_field(:text, "width", type: :quantitative)
        ])

      assert vl == Data.heatmap(@data, x: "height", y: "weight", color: "height", text: "width")
    end

    test "raises an error when the x field is not given" do
      assert_raise ArgumentError, "the x field is required to plot a heatmap", fn ->
        Data.heatmap(@data, y: "y")
      end
    end

    test "raises an error when the y field is not given" do
      assert_raise ArgumentError, "the y field is required to plot a heatmap", fn ->
        Data.heatmap(@data, x: "x", text: "text")
      end
    end
  end

  describe "density heatmap" do
    test "simple density heatmap" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count)
        ])

      assert vl == Data.density_heatmap(@data, x: "height", y: "weight", color: "height")
    end

    test "with title" do
      vl =
        Vl.new(title: "Density heatmap")
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count)
        ])

      assert vl ==
               Vl.new(title: "Density heatmap")
               |> Data.density_heatmap(@data, x: "height", y: "weight", color: "height")
    end

    test "with specified bins" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: [maxbins: 10])
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: [maxbins: 10])
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: [field: "height", bin: [maxbins: 10]],
                 y: [field: "weight", bin: [maxbins: 10]],
                 color: "height"
               )
    end

    test "with specified aggregate for color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :mean)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: [field: "height", aggregate: :mean]
               )
    end

    test "with text" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:text, "height", type: :quantitative, aggregate: :count)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height"
               )
    end

    test "with text_color" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:text, "height", type: :quantitative, aggregate: :count)
          |> Vl.encode_field(:color, "height", type: :quantitative)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height",
                 text_color: "height"
               )
    end

    test "with text_color with condition" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:text, "height", type: :quantitative, aggregate: :count)
          |> Vl.encode_field(:color, "height",
            type: :quantitative,
            condition: [
              [test: "datum['height'] < 0", value: :white],
              [test: "datum['height'] >= 0", value: :black]
            ]
          )
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height",
                 text_color: [
                   field: "height",
                   condition: [
                     [test: "datum['height'] < 0", value: :white],
                     [test: "datum['height'] >= 0", value: :black]
                   ]
                 ]
               )
    end

    test "with specified aggregate for text" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:text, "height", type: :quantitative, aggregate: :mean)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: [field: "height", aggregate: :mean]
               )
    end

    test "with text different from the axes" do
      vl =
        Vl.new()
        |> Vl.data_from_values(@data, only: ["height", "weight", "width"])
        |> Vl.layers([
          Vl.new()
          |> Vl.mark(:rect)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
          Vl.new()
          |> Vl.mark(:text)
          |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
          |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
          |> Vl.encode_field(:text, "width", type: :quantitative, aggregate: :count)
        ])

      assert vl ==
               Data.density_heatmap(@data,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "width"
               )
    end

    test "raises an error when the x field is not given" do
      assert_raise ArgumentError, "the x field is required to plot a density heatmap", fn ->
        Data.density_heatmap(@data, y: "y")
      end
    end

    test "raises an error when the y field is not given" do
      assert_raise ArgumentError, "the y field is required to plot a density heatmap", fn ->
        Data.density_heatmap(@data, x: "x", text: "text")
      end
    end

    test "raises an error when the color field is not given" do
      assert_raise ArgumentError, "the color field is required to plot a density heatmap", fn ->
        Data.density_heatmap(@data, x: "x", y: "y")
      end
    end
  end

  describe "jointplot" do
    test "simple jointplot" do
      vl =
        Vl.new(spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl == Data.joint_plot(@data, :circle, x: "height", y: "weight")
    end

    test "with title" do
      vl =
        Vl.new(title: "Jointplot", spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl ==
               Vl.new(title: "Jointplot")
               |> Data.joint_plot(@data, :circle, x: "height", y: "weight")
    end

    test "with custom width" do
      vl =
        Vl.new(title: "Jointplot", width: 500, spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60, width: 500)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new(width: 500)
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl ==
               Vl.new(title: "Jointplot", width: 500)
               |> Data.joint_plot(@data, :circle, x: "height", y: "weight")
    end

    test "with custom height" do
      vl =
        Vl.new(title: "Jointplot", height: 350, spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new(height: 350)
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60, height: 350)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl ==
               Vl.new(title: "Jointplot", height: 350)
               |> Data.joint_plot(@data, :circle, x: "height", y: "weight")
    end

    test "with custom width and height" do
      vl =
        Vl.new(title: "Jointplot", width: 500, height: 350, spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60, width: 500)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new(width: 500, height: 350)
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60, height: 350)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl ==
               Vl.new(title: "Jointplot", width: 500, height: 350)
               |> Data.joint_plot(@data, :circle, x: "height", y: "weight")
    end

    test "with color" do
      vl =
        Vl.new(spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight", "width"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative)
              |> Vl.encode_field(:color, "width", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl == Data.joint_plot(@data, :circle, x: "height", y: "weight", color: "width")
    end

    test "with text" do
      vl =
        Vl.new(spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight", "width"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.mark(:circle)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative)
              |> Vl.encode_field(:text, "width", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl == Data.joint_plot(@data, :circle, x: "height", y: "weight", text: "width")
    end

    test "mark with options" do
      vl =
        Vl.new(spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :count, title: ""),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.mark(:point, filled: true)
              |> Vl.encode_field(:x, "height", type: :quantitative)
              |> Vl.encode_field(:y, "weight", type: :quantitative),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight", type: :quantitative, aggregate: :count, title: "")
            ])
          ],
          :vertical
        )

      assert vl == Data.joint_plot(@data, [type: :point, filled: true], x: "height", y: "weight")
    end

    test "with a supported specialized as mark" do
      vl =
        Vl.new(spacing: 15, bounds: :flush)
        |> Vl.data_from_values(@data, only: ["height", "weight"])
        |> Vl.concat(
          [
            Vl.new(height: 60)
            |> Vl.mark(:bar)
            |> Vl.encode_field(:x, "height", type: :quantitative, bin: true, axis: nil)
            |> Vl.encode_field(:y, "height",
              type: :quantitative,
              aggregate: :count,
              title: ""
            ),
            Vl.new(spacing: 15, bounds: :flush)
            |> Vl.concat([
              Vl.new()
              |> Vl.layers([
                Vl.new()
                |> Vl.mark(:rect)
                |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
                |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
                |> Vl.encode_field(:color, "height", type: :quantitative, aggregate: :count),
                Vl.new()
                |> Vl.mark(:text)
                |> Vl.encode_field(:x, "height", type: :quantitative, bin: true)
                |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true)
                |> Vl.encode_field(:text, "height", type: :quantitative, aggregate: :count)
              ]),
              Vl.new(width: 60)
              |> Vl.mark(:bar)
              |> Vl.encode_field(:y, "weight", type: :quantitative, bin: true, axis: nil)
              |> Vl.encode_field(:x, "weight",
                type: :quantitative,
                aggregate: :count,
                title: ""
              )
            ])
          ],
          :vertical
        )

      assert vl ==
               Data.joint_plot(
                 @data,
                 :density_heatmap,
                 x: "height",
                 y: "weight",
                 color: "height",
                 text: "height"
               )
    end

    test "raises an error when the x field is not given" do
      assert_raise ArgumentError, "the x field is required to plot a jointplot", fn ->
        Data.joint_plot(@data, :point, y: "y")
      end
    end

    test "raises an error when the y field is not given" do
      assert_raise ArgumentError, "the y field is required to plot a jointplot", fn ->
        Data.joint_plot(@data, :bar, x: "x", text: "text")
      end
    end
  end

  describe "polar" do
    defp deg_to_rad(x), do: x * :math.pi() / 180

    test "polar_grid+polar_plot" do
      radius_marks = [1, 3, 5]
      grid = Data.polar_grid(radius_marks)

      angle_marks = [-360, -360, -270, -180, -90, 0]
      angle_marks2 = [-360, -270, -180, -90, 0, 0]
      angle_offset = 90

      angle_layers =
        Enum.zip_with([angle_marks, angle_marks2], fn [t, t2] ->
          is_360 = :math.fmod(t, 360) == 0

          label =
            if (t != 0 and not is_360) or t == 0 do
              Vl.new()
              |> Vl.mark(:text,
                text: to_string(abs(t)) <> "º",
                theta: "#{deg_to_rad(t + angle_offset)}",
                radius: [expr: "min(width, height) * 0.55"]
              )
            else
              []
            end

          theta = deg_to_rad(t + angle_offset)
          theta2 = deg_to_rad(t2 + angle_offset)

          [
            Vl.new()
            |> Vl.mark(:arc,
              theta: "#{theta}",
              theta2: "#{theta2}",
              stroke: "black",
              stroke_opacity: 1,
              opacity: 1,
              color: "white"
            ),
            label
          ]
        end)

      max_radius = Enum.max(radius_marks)

      radius_marks_vl =
        Enum.map(radius_marks, fn r ->
          Vl.mark(Vl.new(), :arc,
            radius: [expr: "#{r / max_radius} * min(width, height)/2"],
            radius2: [expr: "#{r / max_radius} * min(width, height)/2 + 1"],
            theta: "0",
            theta2: "#{2 * :math.pi()}",
            color: "black",
            opacity: 1,
            stroke_color: "black"
          )
        end)

      radius_ruler_vl = [
        Vl.new()
        |> Vl.data_from_values(%{
          r: radius_marks,
          theta: Enum.map(radius_marks, fn _ -> :math.pi() / 4 end)
        })
        |> Vl.mark(:text,
          radius: [expr: "datum.r  * min(width, height) / (2 * #{max_radius})"],
          theta: :math.pi() / 2,
          dy: 10,
          dx: -10,
          color: "black"
        )
        |> Vl.encode_field(:text, "r", type: :quantitative)
      ]

      layers =
        angle_layers ++ radius_marks_vl ++ radius_ruler_vl

      vl_polar_config = %{
        direction: :counter_clockwise,
        radius_marks: radius_marks,
        angle_offset: 0,
        hide_axes: true
      }

      expected =
        Vl.new()
        |> Vl.data_from_values(%{"_r" => [0]})
        |> Vl.layers(List.flatten(layers))
        |> put_in([Access.key(:spec), "_vl_polar_config"], vl_polar_config)

      assert expected == grid

      color_key = "Line Groups"

      data = %{
        "r" => [1, 2, 3],
        "theta" => [0, 30, 45],
        color_key => List.duplicate("First Line", 3)
      }

      list = [
        {data, type: :line, point: true, interpolate: "cardinal"},
        {data, :point}
      ]

      pi = :math.pi()

      {plot, layers} =
        for {data, mark} <- list, reduce: {grid, []} do
          {v, layers} ->
            r = "r"
            theta = "theta"

            x_formula = "datum.x_linear"
            y_formula = "datum.y_linear"

            calculated_field_opts =
              [
                type: :quantitative,
                scale: [
                  domain: [-max_radius, max_radius]
                ],
                axis: [
                  grid: false,
                  ticks: false,
                  domain_opacity: 0,
                  labels: false,
                  title: false,
                  domain: false,
                  offset: 50
                ]
              ]

            data_fields = [r, theta, color_key]

            auto_tooltip =
              Enum.map(data, fn
                {^color_key, _} ->
                  [field: to_string(color_key), type: :nominal]

                {field, _} ->
                  [field: to_string(field), type: :quantitative]
              end)

            tooltip = auto_tooltip

            layer =
              Vl.new()
              |> Vl.data_from_values(data, only: data_fields)
              |> Vl.transform(
                calculate: "datum.r * cos(datum.theta * #{pi / 180})",
                as: "x_linear"
              )
              |> Vl.transform(
                calculate: "datum.r * sin(+datum.theta * #{pi / 180})",
                as: "y_linear"
              )
              |> Vl.transform(calculate: x_formula, as: "x")
              |> Vl.transform(calculate: y_formula, as: "y")
              |> then(fn vl ->
                if mark == :point do
                  Vl.mark(vl, :point)
                else
                  {mark, opts} = Keyword.pop!(mark, :type)
                  Vl.mark(vl, mark, opts)
                end
              end)
              |> then(fn vl ->
                Vl.encode_field(vl, :color, color_key,
                  type: :nominal,
                  scale: []
                )
              end)
              |> Vl.encode_field(:x, "x", calculated_field_opts)
              |> Vl.encode_field(:y, "y", calculated_field_opts)
              |> Vl.encode_field(:order, "theta")
              |> Vl.encode(:tooltip, tooltip)

            v = VegaLite.Data.polar_plot(v, data, mark, r: "r", theta: "theta", color: color_key)

            {v, [layer | layers]}
        end

      layers = Enum.reverse(layers) |> Enum.map(&(&1 |> Vl.to_spec() |> Map.delete("$schema")))

      expected =
        update_in(expected.spec, fn spec ->
          Map.update(spec, "layer", layers, &(&1 ++ layers))
        end)

      assert expected == plot
    end

    test "polar_plot raises if input vl is not polar" do
      assert_raise ArgumentError,
                   "the given VegaLite spec must be generated from VegaLite.Data.polar_grid/3",
                   fn ->
                     Data.polar_plot(Vl.new(), %{}, :point, [])
                   end
    end
  end
end
