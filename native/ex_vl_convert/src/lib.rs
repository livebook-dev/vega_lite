use rustler::Atom;
use rustler::Encoder;
use rustler::Env;
use rustler::NifTuple;
use rustler::Term;

use vl_convert_rs::converter::VgOpts;
use vl_convert_rs::converter::VlOpts;
use vl_convert_rs::VlConverter;
use vl_convert_rs::VlVersion;

// use webp::{Encoder, WebPMemory};

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
    let vl_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return error_tuple("Vega spec is not valid JSON".to_string()),
    };

    let mut converter = VlConverter::new();
    let svg_result = futures::executor::block_on(converter.vega_to_svg(vl_spec, vg_opts()));

    return match svg_result {
        Ok(svg) => ok_string_tuple(svg),
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

    let vl_spec: serde_json::Value = match serde_json::from_str(vega_spec.as_str()) {
        Ok(spec) => spec,
        Err(_err) => return StringTuple(error_tuple("Vega spec is not valid JSON".to_string())),
    };

    let mut converter = VlConverter::new();
    let png_result = futures::executor::block_on(converter.vega_to_png(
        vl_spec,
        vg_opts(),
        Some(scale),
        Some(ppi),
    ));

    return match png_result {
        Ok(svg) => BinaryTuple(ok_binary_tuple(svg)),
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
        Ok(svg) => BinaryTuple(ok_binary_tuple(svg)),
        Err(err) => StringTuple(error_tuple(err.to_string())),
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

// TODO: Clean this up once things get migrated over
// #[rustler::nif(schedule = "DirtyCpu")]
// fn to_jpeg(vega_lite_spec: String, version: String, scale: f32) -> BinaryResultTuple {
//     let mut converter = VlConverter::new();
//
//     let vl_spec: serde_json::Value = serde_json::from_str(vega_lite_spec.as_str()).unwrap();
//
//     let vl_version = match version.as_str() {
//         "5.16" => VlVersion::v5_16,
//         "5.17" => VlVersion::v5_17,
//         "5.18" => VlVersion::v5_18,
//         _ => VlVersion::v5_19,
//     };
//
//     let jpeg = futures::executor::block_on(converter.vegalite_to_jpeg(
//         vl_spec,
//         VlOpts {
//             vl_version: vl_version,
//             ..Default::default()
//         },
//         Some(scale),
//         None,
//     ))
//     .expect("Failed to perform Vega-Lite to Vega conversion");
//
//     return BinaryResultTuple {
//         lhs: atoms::ok(),
//         rhs: jpeg,
//     };
// }
//
// #[rustler::nif(schedule = "DirtyCpu")]
// fn to_webp(vega_lite_spec: String, version: String, scale: f32) -> BinaryResultTuple {
//     let mut converter = VlConverter::new();
//
//     let vl_spec: serde_json::Value = serde_json::from_str(vega_lite_spec.as_str()).unwrap();
//
//     let vl_version = match version.as_str() {
//         "5.16" => VlVersion::v5_16,
//         "5.17" => VlVersion::v5_17,
//         "5.18" => VlVersion::v5_18,
//         _ => VlVersion::v5_19,
//     };
//
//     let png = futures::executor::block_on(converter.vegalite_to_png(
//         vl_spec,
//         VlOpts {
//             vl_version: vl_version,
//             ..Default::default()
//         },
//         Some(scale),
//         None,
//     ))
//     .expect("Failed to perform Vega-Lite to Vega conversion");
//
//     let png_image = image::load_from_memory(&png).unwrap();
//     let encoder: Encoder = Encoder::from_image(&png_image).unwrap();
//     let webp: WebPMemory = encoder.encode(65f32);
//
//     return BinaryResultTuple {
//         lhs: atoms::ok(),
//         rhs: Vec::from(&*webp),
//     };
// }
