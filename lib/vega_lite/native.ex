defmodule VegaLite.Native do
  @moduledoc false

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  use RustlerPrecompiled,
    otp_app: :vega_lite,
    crate: "ex_vl_convert",
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    targets:
      Enum.uniq(["aarch64-unknown-linux-musl" | RustlerPrecompiled.Config.default_targets()]),
    force_build: System.get_env("VEGA_LITE_BUILD") in ["1", "true"]

  # Old
  # def to_jpeg(_vl_json_spec, _version, _scale), do: :erlang.nif_error(:nif_not_loaded)
  # def to_png(_vl_json_spec, _version, _scale), do: :erlang.nif_error(:nif_not_loaded)
  # def to_svg(_vl_json_spec, _version), do: :erlang.nif_error(:nif_not_loaded)

  # New
  # def vega_to_html(), do: :erlang.nif_error(:nif_not_loaded)
  # def vega_to_jpeg(), do: :erlang.nif_error(:nif_not_loaded)
  # def vega_to_pdf(), do: :erlang.nif_error(:nif_not_loaded)
  # def vega_to_png(), do: :erlang.nif_error(:nif_not_loaded)
  # def vega_to_scenegraph(), do: :erlang.nif_error(:nif_not_loaded)
  # def vega_to_svg(), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_html(), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_jpeg(), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_pdf(), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_png(), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_scenegraph(), do: :erlang.nif_error(:nif_not_loaded)
  def vegalite_to_svg(_vl_json_spec, _version), do: :erlang.nif_error(:nif_not_loaded)
  # def vegalite_to_vega(), do: :erlang.nif_error(:nif_not_loaded)
end
