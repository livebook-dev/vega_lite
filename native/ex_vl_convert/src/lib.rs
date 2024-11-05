use rustler::Atom;
use rustler::NifTuple;

use vl_convert_rs::converter::VlOpts;
use vl_convert_rs::{VlConverter, VlVersion};

use webp::{Encoder, WebPMemory};

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
// fn to_png(vega_lite_spec: String, version: String, scale: f32) -> BinaryResultTuple {
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
//     return BinaryResultTuple {
//         lhs: atoms::ok(),
//         rhs: png,
//     };
// }

#[rustler::nif(schedule = "DirtyCpu")]
fn vegalite_to_svg(vega_lite_spec: String, version: String) -> StringResultTuple {
    let mut converter = VlConverter::new();

    let vl_spec: serde_json::Value = serde_json::from_str(vega_lite_spec.as_str()).unwrap();

    let vl_version = match version.as_str() {
        "5.16" => VlVersion::v5_16,
        "5.17" => VlVersion::v5_17,
        "5.18" => VlVersion::v5_18,
        _ => VlVersion::v5_19,
    };

    let svg = futures::executor::block_on(converter.vegalite_to_svg(
        vl_spec,
        VlOpts {
            vl_version: vl_version,
            ..Default::default()
        },
    ))
    .expect("Failed to perform Vega-Lite to Vega conversion");

    return StringResultTuple {
        lhs: atoms::ok(),
        rhs: svg,
    };
}

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

rustler::init!("Elixir.VegaLite.Native");
