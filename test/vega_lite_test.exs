defmodule VegaLiteTest do
  use ExUnit.Case

  alias VegaLite, as: Vl

  describe "data/2" do
    test "raises an error when no properties are given" do
      assert_raise ArgumentError, "expected at least one data property, but none was given", fn ->
        Vl.new() |> Vl.data([])
      end
    end

    test "transforms options to properties" do
      vl =
        Vl.new()
        |> Vl.data(sequence: [start: 0, stop: 12.7, step: 0.1, as: "x"])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "sequence": {
              "start": 0,
              "stop": 12.7,
              "step": 0.1,
              "as": "x"
            }
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "data_from_url/3" do
    test "adds data url to the specification" do
      vl = Vl.new() |> Vl.data_from_url("http://example.com/cats.json")

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "url": "http://example.com/cats.json"
          }
        }
        """)

      assert vl == expected_vl
    end

    test "converts options to properties" do
      vl = Vl.new() |> Vl.data_from_url("http://example.com/cats.csv", format: :csv)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "url": "http://example.com/cats.csv",
            "format": "csv"
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "data_from_values/3" do
    test "adds data values to the specification" do
      data = [
        %{"height" => 170, "weight" => 80},
        %{"height" => 190, "weight" => 85}
      ]

      vl = Vl.new() |> Vl.data_from_values(data)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "values": [
              { "height": 170, "weight": 80 },
              { "height": 190, "weight": 85 }
            ]
          }
        }
        """)

      assert vl == expected_vl
    end

    test "converts key-value data structures to value entries" do
      data = [
        %{height: 170, weight: 80},
        [height: 190, weight: 85]
      ]

      vl = Vl.new() |> Vl.data_from_values(data)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "values": [
              { "height": 170, "weight": 80 },
              { "height": 190, "weight": 85 }
            ]
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "data_from_series/3" do
    test "adds data values to the specification" do
      iterations = 1..3
      scores = [50, 60, 90]

      vl = Vl.new() |> Vl.data_from_series(iteration: iterations, score: scores)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {
            "values": [
              { "iteration": 1, "score": 50 },
              { "iteration": 2, "score": 60 },
              { "iteration": 3, "score": 90 }
            ]
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "datasets_from_values/2" do
    test "adds normalized data values to the specification" do
      data1 = [
        %{"height" => 170, "weight" => 80},
        %{"height" => 190, "weight" => 85}
      ]

      data2 = [
        %{height: 170, weight: 80},
        [height: 190, weight: 85]
      ]

      vl = Vl.new() |> Vl.datasets_from_values(data1: data1, data2: data2)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "datasets": {
            "data1": [
              { "height": 170, "weight": 80 },
              { "height": 190, "weight": 85 }
            ],
            "data2": [
              { "height": 170, "weight": 80 },
              { "height": 190, "weight": 85 }
            ]
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "encode/3" do
    test "raises an error when invalid channel is given" do
      assert_raise ArgumentError, fn ->
        Vl.new() |> Vl.encode(:invalid, value: 2)
      end
    end

    test "raises an error when neither field, value nor datum is specified" do
      assert_raise ArgumentError,
                   "channel definition must include one of the following keys: :field, :value, :datum, but none was given",
                   fn ->
                     Vl.new() |> Vl.encode(:x, type: :quantitative)
                   end
    end

    test "raises an error when invalid type is given" do
      assert_raise ArgumentError, ~r/:qqquant/, fn ->
        Vl.new() |> Vl.encode(:x, value: 2, type: :qqquant)
      end
    end

    test "does not raise when aggregating count" do
      vl = Vl.new() |> Vl.encode(:y, aggregate: :count)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "encoding": {
            "y": { "aggregate": "count" }
          }
        }
        """)

      assert vl == expected_vl
    end

    test "converts options to properties" do
      vl = Vl.new() |> Vl.encode(:y, field: "height", type: :quantitative, aggregate: :mean)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "encoding": {
            "y": { "field": "height", "type": "quantitative", "aggregate": "mean" }
          }
        }
        """)

      assert vl == expected_vl
    end

    test "accepts a list of option lists" do
      vl =
        Vl.new()
        |> Vl.encode(:tooltip, [
          [field: "height", type: :quantitative],
          [field: "width", type: :quantitative]
        ])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "encoding": {
            "tooltip": [
              { "field": "height", "type": "quantitative" },
              { "field": "width", "type": "quantitative" }
            ]
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "encode_field/4" do
    test "raises an error when invalid channel is given" do
      assert_raise ArgumentError, fn ->
        Vl.new() |> Vl.encode_field(:invalid, "height")
      end
    end

    test "raises an error when field is not string" do
      assert_raise ArgumentError, "field must be a string, got: []", fn ->
        Vl.new() |> Vl.encode_field(:x, [])
      end
    end

    test "raises an error when invalid type is given" do
      assert_raise ArgumentError, ~r/:qqquant/, fn ->
        Vl.new() |> Vl.encode_field(:x, "x", type: :qqquant)
      end
    end

    test "adds field encoding to the specification" do
      vl =
        Vl.new()
        |> Vl.encode_field(:x, "age")
        |> Vl.encode_field(:y, "height", type: :quantitative, aggregate: :mean)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "encoding": {
            "x": { "field": "age" },
            "y": { "field": "height", "type": "quantitative", "aggregate": "mean" }
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "encode_repeat/4" do
    test "raises an error when invalid channel is given" do
      assert_raise ArgumentError, fn ->
        Vl.new() |> Vl.encode_repeat(:invalid, :row)
      end
    end

    test "raises an error when invalid repeat type is given" do
      assert_raise ArgumentError,
                   "unknown repeat type, expected one of :repeat, :row, :column, :layer, got: :invalid_repeat_type",
                   fn ->
                     Vl.new() |> Vl.encode_repeat(:x, :invalid_repeat_type)
                   end
    end

    test "adds repeated field encoding to the specification" do
      vl = Vl.new() |> Vl.encode_repeat(:y, :column, type: :quantitative, aggregate: :mean)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "encoding": {
            "y": { "field": { "repeat": "column" }, "type": "quantitative", "aggregate": "mean" }
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "mark/3" do
    test "raises an error when specification already has a mark" do
      vl = Vl.new() |> Vl.mark(:point)

      assert_raise ArgumentError,
                   "cannot add mark to the view, because it is already a single-view specification (has the :mark key defined)",
                   fn ->
                     Vl.mark(vl, :line)
                   end
    end

    test "raises an error when specification is already multi-view" do
      vl = Vl.new() |> Vl.concat([Vl.new(), Vl.new()])

      assert_raise ArgumentError,
                   "cannot add mark to the view, because it is already a multi-view specification (has the :concat key defined)",
                   fn ->
                     Vl.mark(vl, :line)
                   end
    end

    test "raises an error when invalid mark type is given" do
      assert_raise ArgumentError, fn ->
        Vl.new() |> Vl.mark(:invalid)
      end
    end

    test "sets mark type in the specification" do
      vl = Vl.new() |> Vl.mark(:point)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "mark": "point"
        }
        """)

      assert vl == expected_vl
    end

    test "sets mark type to mark definition when options are given" do
      vl = Vl.new() |> Vl.mark(:point, tooltip: true)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "mark": { "type": "point", "tooltip": true }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "transform/2" do
    test "raises an error when no properties are given" do
      assert_raise ArgumentError,
                   "expected at least one transform property, but none was given",
                   fn ->
                     Vl.new() |> Vl.transform([])
                   end
    end

    test "adds transform entry to the specification" do
      vl =
        Vl.new()
        |> Vl.transform(calculate: "sin(datum.x)", as: "sin_x")
        |> Vl.transform(filter: "datum.height > 150")

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "transform": [
            { "calculate": "sin(datum.x)", "as": "sin_x" },
            { "filter": "datum.height > 150" }
          ]
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "param/3" do
    test "raises an error when no properties are given" do
      assert_raise ArgumentError,
                   "expected at least one parameter property, but none was given",
                   fn ->
                     Vl.new() |> Vl.param("my_param", [])
                   end
    end

    test "adds parameter entry to the specification" do
      vl = Vl.new() |> Vl.param("brush", select: [type: :interval, encodings: [:x]])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "params": [
            {
              "name": "brush",
              "select": { "type": "interval", "encodings": ["x"] }
            }
          ]
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "config/2" do
    test "raises an error when no properties are given" do
      assert_raise ArgumentError,
                   "expected at least one config property, but none was given",
                   fn ->
                     Vl.new() |> Vl.config([])
                   end
    end

    test "sets config properties to the specification" do
      vl = Vl.new() |> Vl.config(view: [stroke: :transparent])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "config": {
            "view": { "stroke": "transparent" }
          }
        }
        """)

      assert vl == expected_vl
    end

    test "merges config properties with existing ones int the specification" do
      vl =
        Vl.new()
        |> Vl.config(view: [stroke: :transparent])
        |> Vl.config(padding: 100)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "config": {
            "view": { "stroke": "transparent" },
            "padding": 100
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "projection/2" do
    test "raises an error when no propperties are given" do
      assert_raise ArgumentError,
                   "expected at least one projection property, but none was given",
                   fn ->
                     Vl.new() |> Vl.projection([])
                   end
    end

    test "sets projection properties in the specification" do
      vl = Vl.new() |> Vl.projection(type: :albers_usa)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "projection": { "type": "albersUsa" }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "layers/2" do
    test "raises an error when specification is already single-view" do
      vl = Vl.new() |> Vl.mark(:point)

      assert_raise ArgumentError,
                   "cannot build a layered view, because it is already a single-view specification (has the :mark key defined)",
                   fn ->
                     Vl.layers(vl, [Vl.new(), Vl.new()])
                   end
    end

    test "raises an error when specification is already multi-view" do
      vl = Vl.new() |> Vl.concat([Vl.new(), Vl.new()])

      assert_raise ArgumentError,
                   "cannot build a layered view, because it is already a multi-view specification (has the :concat key defined)",
                   fn ->
                     Vl.layers(vl, [Vl.new(), Vl.new()])
                   end
    end

    test "sets layers from child specifications" do
      vl =
        Vl.new()
        |> Vl.layers([
          Vl.new() |> Vl.mark(:line),
          Vl.new() |> Vl.mark(:rule)
        ])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "layer": [
            { "mark": "line" },
            { "mark": "rule" }
          ]
        }
        """)

      assert vl == expected_vl
    end

    test "raises an error if a child specification has top-level properties" do
      assert_raise ArgumentError,
                   "child view specification cannot have top-level keys, found: :padding",
                   fn ->
                     Vl.new()
                     |> Vl.layers([
                       Vl.new(padding: 100),
                       Vl.new()
                     ])
                   end
    end
  end

  describe "concat/2" do
    test "raises an error when specification is already single-view" do
      vl = Vl.new() |> Vl.mark(:point)

      assert_raise ArgumentError,
                   "cannot build a concatenated view, because it is already a single-view specification (has the :mark key defined)",
                   fn ->
                     Vl.concat(vl, [Vl.new(), Vl.new()])
                   end
    end

    test "raises an error when specification is already multi-view" do
      vl = Vl.new() |> Vl.concat([Vl.new(), Vl.new()])

      assert_raise ArgumentError,
                   "cannot build a concatenated view, because it is already a multi-view specification (has the :concat key defined)",
                   fn ->
                     Vl.concat(vl, [Vl.new(), Vl.new()])
                   end
    end

    test "raises an error when invalid concatenation type is given" do
      assert_raise ArgumentError,
                   "invalid concat type, expected :wrappable, :horizontal or :vertical, got: :invalid",
                   fn ->
                     Vl.new() |> Vl.concat([Vl.new(), Vl.new()], :invalid)
                   end
    end

    test "sets concatenated child specifications" do
      vl =
        Vl.new()
        |> Vl.concat([
          Vl.new() |> Vl.mark(:line),
          Vl.new() |> Vl.mark(:rule)
        ])

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "concat": [
            { "mark": "line" },
            { "mark": "rule" }
          ]
        }
        """)

      assert vl == expected_vl
    end

    test "supports horizontal concatenation" do
      vl =
        Vl.new()
        |> Vl.concat(
          [
            Vl.new() |> Vl.mark(:line),
            Vl.new() |> Vl.mark(:rule)
          ],
          :horizontal
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "hconcat": [
            { "mark": "line" },
            { "mark": "rule" }
          ]
        }
        """)

      assert vl == expected_vl
    end

    test "supports vertical concatenation" do
      vl =
        Vl.new()
        |> Vl.concat(
          [
            Vl.new() |> Vl.mark(:line),
            Vl.new() |> Vl.mark(:rule)
          ],
          :vertical
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "vconcat": [
            { "mark": "line" },
            { "mark": "rule" }
          ]
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "facet/3" do
    test "raises an error when specification is already single-view" do
      vl = Vl.new() |> Vl.mark(:point)

      assert_raise ArgumentError,
                   "cannot build a facet view, because it is already a single-view specification (has the :mark key defined)",
                   fn ->
                     Vl.facet(vl, [field: "genre"], Vl.new())
                   end
    end

    test "raises an error when specification is already multi-view" do
      vl = Vl.new() |> Vl.facet([field: "genre"], Vl.new())

      assert_raise ArgumentError,
                   "cannot build a facet view, because it is already a multi-view specification (has the :facet key defined)",
                   fn ->
                     Vl.facet(vl, [field: "country"], Vl.new())
                   end
    end

    test "raises an error when invalid facet definition is given" do
      assert_raise ArgumentError,
                   "facet definition must be either a field definition (keywrod list with the :field key) or a mapping with :row/:column keys, got: [invalid: 1]",
                   fn ->
                     Vl.new() |> Vl.facet([invalid: 1], Vl.new())
                   end
    end

    test "sets facet definition and view template specification" do
      vl =
        Vl.new()
        |> Vl.facet(
          [field: "genre"],
          Vl.new() |> Vl.mark(:point)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "facet": { "field": "genre" },
          "spec": {
            "mark": "point"
          }
        }
        """)

      assert vl == expected_vl
    end

    test "supports row/column facet definition" do
      vl =
        Vl.new()
        |> Vl.facet(
          [
            row: [field: "country", title: "Country"],
            column: [field: "year", title: "Year"]
          ],
          Vl.new() |> Vl.mark(:point)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "facet": {
            "row": { "field": "country", "title": "Country" },
            "column": { "field": "year", "title": "Year" }
          },
          "spec": {
            "mark": "point"
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "repeat/3" do
    test "raises an error when specification is already single-view" do
      vl = Vl.new() |> Vl.mark(:point)

      assert_raise ArgumentError,
                   "cannot build a repeated view, because it is already a single-view specification (has the :mark key defined)",
                   fn ->
                     Vl.repeat(vl, ["temp_max", "precipitation", "wind"], Vl.new())
                   end
    end

    test "raises an error when specification is already multi-view" do
      vl = Vl.new() |> Vl.repeat(["temp_max", "precipitation", "wind"], Vl.new())

      assert_raise ArgumentError,
                   "cannot build a repeated view, because it is already a multi-view specification (has the :repeat key defined)",
                   fn ->
                     Vl.repeat(vl, ["temp_max", "precipitation", "wind"], Vl.new())
                   end
    end

    test "raises an error when invalid repeat definition is given" do
      assert_raise ArgumentError,
                   "repeat definition must be either list of fields or a mapping with :row/:column/:layer keys, got: [invalid: 1]",
                   fn ->
                     Vl.new() |> Vl.repeat([invalid: 1], Vl.new())
                   end
    end

    test "sets repeat definition and view template specification" do
      vl =
        Vl.new()
        |> Vl.repeat(
          ["temp_max", "precipitation", "wind"],
          Vl.new() |> Vl.mark(:point)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "repeat": ["temp_max", "precipitation", "wind"],
          "spec": {
            "mark": "point"
          }
        }
        """)

      assert vl == expected_vl
    end

    test "supports row/column repeat definition" do
      vl =
        Vl.new()
        |> Vl.repeat(
          [
            row: ["beak_length", "beak_depth", "flipper_length", "body_mass"],
            column: ["body_mass", "flipper_length", "beak_depth", "beak_length"]
          ],
          Vl.new() |> Vl.mark(:point)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "repeat": {
            "row": ["beak_length", "beak_depth", "flipper_length", "body_mass"],
            "column": ["body_mass", "flipper_length", "beak_depth", "beak_length"]
          },
          "spec": {
            "mark": "point"
          }
        }
        """)

      assert vl == expected_vl
    end

    test "supports layer repeat definition" do
      vl =
        Vl.new()
        |> Vl.repeat(
          [
            layer: ["beak_length", "beak_depth", "flipper_length", "body_mass"]
          ],
          Vl.new() |> Vl.mark(:point)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "repeat": {
            "layer": ["beak_length", "beak_depth", "flipper_length", "body_mass"]
          },
          "spec": {
            "mark": "point"
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "resolve/3" do
    test "raises an error when no properties are given" do
      assert_raise ArgumentError,
                   "expected at least one resolve property, but none was given",
                   fn ->
                     Vl.new() |> Vl.resolve(:axis, [])
                   end
    end

    test "raises an error when invalid resolution key is given" do
      assert_raise ArgumentError,
                   "unknown resolution key, expected one of :scale, :axis, :legend, got: :scaaale",
                   fn ->
                     Vl.new() |> Vl.resolve(:scaaale, y: :independent)
                   end
    end

    test "raises an error when invalid channel is specified in options" do
      assert_raise ArgumentError, fn ->
        Vl.new() |> Vl.resolve(:axis, unknown: :independent)
      end
    end

    test "raises an error when invalid resolution type is specified in options" do
      assert_raise ArgumentError,
                   "unknown resolution type, expected one of :shared, :independent, got: :unknown",
                   fn ->
                     Vl.new() |> Vl.resolve(:axis, x: :unknown)
                   end
    end

    test "adds resolution entry to the specification" do
      vl = Vl.new() |> Vl.resolve(:scale, y: :independent)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "resolve": {
            "scale": { "y": "independent" }
          }
        }
        """)

      assert vl == expected_vl
    end
  end

  describe "integration" do
    test "[single-view] multiple encodings" do
      vl =
        Vl.new(description: "Stock prices of 5 Tech Companies over Time.")
        |> Vl.data_from_url("https://vega.github.io/editor/data/stocks.csv", format: :csv)
        |> Vl.encode_field(:x, "date", type: :temporal)
        |> Vl.encode_field(:y, "price", type: :quantitative)
        |> Vl.encode_field(:size, "price", type: :quantitative)
        |> Vl.encode_field(:color, "symbol", type: :nominal)
        |> Vl.mark(:trail)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "description": "Stock prices of 5 Tech Companies over Time.",
          "data": {"url": "https://vega.github.io/editor/data/stocks.csv", "format": "csv"},
          "mark": "trail",
          "encoding": {
            "x": {"field": "date", "type": "temporal"},
            "y": {"field": "price", "type": "quantitative"},
            "size": {"field": "price", "type": "quantitative"},
            "color": {"field": "symbol", "type": "nominal"}
          }
        }
        """)

      assert vl == expected_vl
    end

    test "[single-view] generated data with transform" do
      vl =
        Vl.new(width: 300, height: 150)
        |> Vl.data(sequence: [start: 0, stop: 12.7, step: 0.1, as: "x"])
        |> Vl.transform(calculate: "sin(datum.x)", as: "sin(x)")
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, "x", type: :quantitative)
        |> Vl.encode_field(:y, "sin(x)", type: :quantitative)

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "width": 300,
          "height": 150,
          "data": {
            "sequence": {
              "start": 0,
              "stop": 12.7,
              "step": 0.1,
              "as": "x"
            }
          },
          "transform": [
            {
              "calculate": "sin(datum.x)",
              "as": "sin(x)"
            }
          ],
          "mark": "line",
          "encoding": {
            "x": {
              "field": "x",
              "type": "quantitative"
            },
            "y": {
              "field": "sin(x)",
              "type": "quantitative"
            }
          }
        }
        """)

      assert vl == expected_vl
    end

    test "[multi-view] trellis plot" do
      vl =
        Vl.new()
        |> Vl.data_from_url("https://vega.github.io/editor/data/penguins.json")
        |> Vl.repeat(
          [
            row: [
              "Beak Length (mm)",
              "Beak Depth (mm)",
              "Flipper Length (mm)",
              "Body Mass (g)"
            ],
            column: [
              "Body Mass (g)",
              "Flipper Length (mm)",
              "Beak Depth (mm)",
              "Beak Length (mm)"
            ]
          ],
          Vl.new(width: 150, height: 150)
          |> Vl.mark(:point)
          |> Vl.encode_repeat(:x, :column, type: :quantitative, scale: [zero: false])
          |> Vl.encode_repeat(:y, :row, type: :quantitative, scale: [zero: false])
          |> Vl.encode_field(:color, "Species", type: :nominal)
        )

      expected_vl =
        Vl.from_json("""
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "data": {"url": "https://vega.github.io/editor/data/penguins.json"},
          "repeat": {
            "row": [
              "Beak Length (mm)",
              "Beak Depth (mm)",
              "Flipper Length (mm)",
              "Body Mass (g)"
            ],
            "column": [
              "Body Mass (g)",
              "Flipper Length (mm)",
              "Beak Depth (mm)",
              "Beak Length (mm)"
            ]
          },
          "spec": {
            "width": 150,
            "height": 150,
            "mark": "point",
            "encoding": {
              "x": {
                "field": {"repeat": "column"},
                "type": "quantitative",
                "scale": {"zero": false}
              },
              "y": {
                "field": {"repeat": "row"},
                "type": "quantitative",
                "scale": {"zero": false}
              },
              "color": {"field": "Species", "type": "nominal"}
            }
          }
        }
        """)

      assert vl == expected_vl
    end
  end
end
