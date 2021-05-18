defmodule VegaLite.MixProject do
  use Mix.Project

  def project do
    [
      app: :vega_lite,
      version: "0.1.0-dev",
      elixir: "~> 1.11",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:jason, "~> 1.2"}
    ]
  end
end
