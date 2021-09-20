defmodule VegaLite.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description "Elixir bindings to Vega-Lite"

  def project do
    [
      app: :vega_lite,
      version: @version,
      description: @description,
      name: "VegaLite",
      elixir: "~> 1.7",
      deps: deps(),
      docs: docs(),
      package: package(),
      # Modules used by VegaLite.WxViewer if available
      xref: [exclude: [:wx, :wx_object, :wxFrame, :wxWebView]],
      dialyzer: [
        plt_add_apps: [:wx]
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:jason, "~> 1.2", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "VegaLite",
      source_url: "https://github.com/elixir-nx/vega_lite",
      source_ref: "v#{@version}"
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elixir-nx/vega_lite"
      }
    ]
  end
end
