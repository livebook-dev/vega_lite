use rustler::Atom;
use rustler::Encoder;
use rustler::Env;
use rustler::NifTuple;
use rustler::Term;

use vl_convert_rs::converter::VgOpts;
use vl_convert_rs::converter::VlOpts;
use vl_convert_rs::VlConverter;
use vl_convert_rs::VlVersion;

// +-------------------------------------+
// |        Rustler Return Types         |
// +-------------------------------------+

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

#[derive(NifTuple)]
struct StringResultTuple {
    lhs: Atom,
    rhs: String,
}

#[derive(NifTuple)]
struct BinaryResultTuple {
    lhs: Atom,
    rhs: Vec<u8>,
}

enum Either<BinaryResultTuple, StringResultTuple> {
    BinaryTuple(BinaryResultTuple),
    StringTuple(StringResultTuple),
}

impl Encoder for Either<BinaryResultTuple, StringResultTuple> {
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        use Either::{BinaryTuple, StringTuple};

        return match self {
            BinaryTuple(result) => result.encode(env),
            StringTuple(result) => result.encode(env),
        };
    }
}

// +-------------------------------------+
// |            Vega Functions           |
// +-------------------------------------+

#[rustler::nif(schedule = "DirtyCpu")]
fn vega_to_svg(vega_spec: String) -> StringResultTuple {
    let vg_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("Vega spec is not valid JSON".to_string()),
    };

    let mut converter = VlConverter::new();
    let svg_result = futures::executor::block_on(converter.vega_to_svg(vg_spec, vg_opts()));

    return match svg_result {
        Ok(svg) => ok_string_tuple(svg),
        Err(err) => error_tuple(err.to_string()),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vega_to_html(vega_spec: String, bundle: bool, renderer: String) -> StringResultTuple {
    let vg_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("Vega spec is not valid JSON".to_string()),
    };

    let renderer_enum = match renderer.parse() {
        Ok(renderer_enum) => renderer_enum,
        Err(_err) => return error_tuple("Invalid renderer provided".to_string()),
    };

    let mut converter = VlConverter::new();
    let html_result = futures::executor::block_on(converter.vega_to_html(
        vg_spec,
        vg_opts(),
        bundle,
        renderer_enum,
    ));

    return match html_result {
        Ok(html) => ok_string_tuple(html),
        Err(err) => error_tuple(err.to_string()),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vega_to_png(
    vega_spec: String,
    scale: f32,
    ppi: f32,
) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vg_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return StringTuple(error_tuple("Vega spec is not valid JSON".to_string())),
    };

    let mut converter = VlConverter::new();
    let jpeg_result = futures::executor::block_on(converter.vega_to_png(
        vg_spec,
        vg_opts(),
        Some(scale),
        Some(ppi),
    ));

    return match jpeg_result {
        Ok(jpeg) => BinaryTuple(ok_binary_tuple(jpeg)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vega_to_jpeg(
    vega_spec: String,
    scale: f32,
    quality: u8,
) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vg_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => {
            return StringTuple(error_tuple("VegaLite spec is not valid JSON".to_string()))
        }
    };

    let mut converter = VlConverter::new();
    let jpeg_result = futures::executor::block_on(converter.vega_to_jpeg(
        vg_spec,
        vg_opts(),
        Some(scale),
        Some(quality),
    ));

    return match jpeg_result {
        Ok(jpeg) => BinaryTuple(ok_binary_tuple(jpeg)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vega_to_pdf(vega_spec: String) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vg_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return StringTuple(error_tuple("Vega spec is not valid JSON".to_string())),
    };

    let mut converter = VlConverter::new();
    let pdf_result = futures::executor::block_on(converter.vega_to_pdf(vg_spec, vg_opts()));

    return match pdf_result {
        Ok(pdf) => BinaryTuple(ok_binary_tuple(pdf)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

// +-------------------------------------+
// |          VegaLite Functions         |
// +-------------------------------------+

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_svg(vega_lite_spec: String) -> StringResultTuple {
    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("VegaLite spec is not valid JSON".to_string()),
    };

    let mut converter = VlConverter::new();
    let svg_result = futures::executor::block_on(converter.vegalite_to_svg(vl_spec, vl_opts()));

    return match svg_result {
        Ok(svg) => ok_string_tuple(svg),
        Err(err) => error_tuple(err.to_string()),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_html(vega_lite_spec: String, bundle: bool, renderer: String) -> StringResultTuple {
    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("VegaLite spec is not valid JSON".to_string()),
    };

    let renderer_enum = match renderer.parse() {
        Ok(renderer_enum) => renderer_enum,
        Err(_err) => return error_tuple("Invalid renderer provided".to_string()),
    };

    let mut converter = VlConverter::new();
    let html_result = futures::executor::block_on(converter.vegalite_to_html(
        vl_spec,
        vl_opts(),
        bundle,
        renderer_enum,
    ));

    return match html_result {
        Ok(html) => ok_string_tuple(html),
        Err(err) => error_tuple(err.to_string()),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_png(
    vega_lite_spec: String,
    scale: f32,
    ppi: f32,
) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => {
            return StringTuple(error_tuple("VegaLite spec is not valid JSON".to_string()))
        }
    };

    let mut converter = VlConverter::new();
    let png_result = futures::executor::block_on(converter.vegalite_to_png(
        vl_spec,
        vl_opts(),
        Some(scale),
        Some(ppi),
    ));

    return match png_result {
        Ok(png) => BinaryTuple(ok_binary_tuple(png)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_jpeg(
    vega_lite_spec: String,
    scale: f32,
    quality: u8,
) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => {
            return StringTuple(error_tuple("VegaLite spec is not valid JSON".to_string()))
        }
    };

    let mut converter = VlConverter::new();
    let jpeg_result = futures::executor::block_on(converter.vegalite_to_jpeg(
        vl_spec,
        vl_opts(),
        Some(scale),
        Some(quality),
    ));

    return match jpeg_result {
        Ok(jpeg) => BinaryTuple(ok_binary_tuple(jpeg)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_pdf(vega_lite_spec: String) -> Either<BinaryResultTuple, StringResultTuple> {
    use Either::{BinaryTuple, StringTuple};

    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => {
            return StringTuple(error_tuple("VegaLite spec is not valid JSON".to_string()))
        }
    };

    let mut converter = VlConverter::new();
    let pdf_result = futures::executor::block_on(converter.vegalite_to_pdf(vl_spec, vl_opts()));

    return match pdf_result {
        Ok(pdf) => BinaryTuple(ok_binary_tuple(pdf)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
    };
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_vega(vega_lite_spec: String) -> StringResultTuple {
    let vl_spec: serde_json::Value = match serde_json::from_str(vega_lite_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("VegaLite spec is not valid JSON".to_string()),
    };

    let mut converter = VlConverter::new();
    let result = futures::executor::block_on(converter.vegalite_to_vega(vl_spec, vl_opts()));

    return match result {
        Ok(result) => ok_string_tuple(result.to_string()),
        Err(err) => error_tuple(err.to_string()),
    };
}
// +-------------------------------------+
// |          Helper Functions           |
// +-------------------------------------+

fn ok_string_tuple(data: String) -> StringResultTuple {
    return StringResultTuple {
        lhs: atoms::ok(),
        rhs: data,
    };
}

fn ok_binary_tuple(data: Vec<u8>) -> BinaryResultTuple {
    return BinaryResultTuple {
        lhs: atoms::ok(),
        rhs: data,
    };
}

fn error_tuple(error: String) -> StringResultTuple {
    return StringResultTuple {
        lhs: atoms::error(),
        rhs: error.to_string(),
    };
}

fn vg_opts() -> VgOpts {
    return VgOpts {
        ..Default::default()
    };
}

fn vl_opts() -> VlOpts {
    return VlOpts {
        vl_version: VlVersion::v5_20,
        ..Default::default()
    };
}

rustler::init!("Elixir.VegaLite.Native");
