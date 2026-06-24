{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/da5ad661ba4e5ef59ba743f0d112cbc30e474f32";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    v_flakes.url = "github:valeratrades/v_flakes/6062f652effc94be053865d58ff03c697c31ecb6";
  };

  outputs = { self, nixpkgs, flake-utils, v_flakes }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        accent = (import ./logo/logo_colors.nix).accent_color;
        # dark: accent bg + white logo; light: white bg + accent logo. ($accent is build-time.)
        render = name: fill: bg: ''
          sed "s/black/${fill}/g" logo/logo.svg > ${name}.svg
          resvg --width 370 ${name}.svg ${name}-content.png
          magick ${name}-content.png -background "${bg}" -gravity center -extent 640x640 -flatten logo.${name}.png
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
          installPhase = "install -Dm644 logo.dark.png logo.light.png -t $out";
        };

        devShells.default = pkgs.mkShell {
          shellHook = ''
            cp -f ${(v_flakes.files.gitattributes { inherit pkgs; lfs = false; })} ./.gitattributes
            cp -f ${(v_flakes.files.gitignore { inherit pkgs; langs = []; })} ./.gitignore
          '';
        };
      });
}
