{
  inputs = {
    v_flakes.url = "github:valeratrades/v_flakes?ref=v1.6";
  };

  outputs = { self, v_flakes }:
    let
      inherit (v_flakes) flake-utils;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import v_flakes.default_nixpkgs { inherit system; };
        accent = (import ./logo/logo_colors.nix).accent_color;
        # dark: accent bg + white logo; light: white bg + accent logo. ($accent is build-time.)
        # 175 matches the old 370/640 proportion, - smallest reasonable fit.
        render = name: fill: bg: ''
          sed "s/black/${fill}/g" logo/logo.svg > ${name}.svg
          for size in 175 225 275; do
            resvg --width $size ${name}.svg ${name}-content.png
            dims=$(magick identify -format "%wx%h" ${name}-content.png)
            magick ${name}-content.png -background "${bg}" -gravity center -extent 300x300 -flatten "logo.300x300-$dims.${name}.png"
          done
        '';
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "logo";
          src = ./.;
          nativeBuildInputs = with pkgs; [ rust-script cargo rustc resvg imagemagick ];
          buildPhase = ''
            export HOME=$TMPDIR RUSTC_WRAPPER= CARGO_NET_OFFLINE=true
            accent=$(rust-script logo/oklch.rs ${toString accent.L} ${toString accent.C} ${toString accent.H})
            ${render "dark" "white" "$accent"}
            ${render "light" "$accent" "white"}
          '';
          installPhase = "install -Dm644 logo.300x300-*.png -t $out";
        };

        devShells.default = pkgs.mkShell {
          shellHook = ''
            cp -f ${(v_flakes.files.gitattributes { inherit pkgs; lfs = false; })} ./.gitattributes
            cp -f ${(v_flakes.files.gitignore { inherit pkgs; langs = []; })} ./.gitignore
          '';
        };
      });
}
