defmodule VegaLite.MixProject do
  use Mix.Project

  def project do
    [
      app: :vega_lite,
      version: "0.1.0-dev",
      elixir: "~> 1.7",
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:jason, "~> 1.2", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "VegaLite",
      source_url: "https://github.com/jonatanklosko/vega_lite",
      source_ref: "main",
      extras: [
        "README.md",
        "guides/examples.md"
      ]
    ]
  end
end
