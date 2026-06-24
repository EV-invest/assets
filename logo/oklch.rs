//! OKLCH (L C H) -> sRGB hex. Single source of truth for logo_colors.nix -> rendered assets.
use std::env::args;

fn main() {
    let a: Vec<f64> = args().skip(1).map(|s| s.parse().expect("L C H as floats")).collect();
    let [l, c, h_deg] = a[..] else { panic!("usage: oklch.rs L C H") };
    let h = h_deg.to_radians();
    let (oa, ob) = (c * h.cos(), c * h.sin());

    let l_ = (l + 0.3963377774 * oa + 0.2158037573 * ob).powi(3);
    let m_ = (l - 0.1055613458 * oa - 0.0638541728 * ob).powi(3);
    let s_ = (l - 0.0894841775 * oa - 1.2914855480 * ob).powi(3);

    let lin = [
        4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
        -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
        -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_,
    ];
    let hex: String = lin
        .iter()
        .map(|&x| {
            let x = x.clamp(0.0, 1.0);
            let s = if x <= 0.0031308 { 12.92 * x } else { 1.055 * x.powf(1.0 / 2.4) - 0.055 };
            format!("{:02X}", (s * 255.0).round() as u8)
        })
        .collect();
    println!("#{hex}");
}
