{
  description = "SDR Test";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    eloy.url = "github:eloycoto/nix-custom-overlay";
    rust-overlay.url = "github:oxalica/rust-overlay";

  };
  outputs = { self, nixpkgs, flake-utils, eloy, rust-overlay }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              eloy.overlays.default
              (import rust-overlay)
            ];
          };

          extraPythonPackages = with pkgs.gnuradio.python.pkgs; [
            numpy
          ];

          combinedAlsaPlugins = pkgs.symlinkJoin {
            name = "combined-alsa-plugins";
            paths = [
              "${pkgs.alsa-plugins}/lib/alsa-lib"
              "${pkgs.pipewire}/lib/alsa-lib"
            ];
          };

        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = with pkgs; [
              alsa-lib
              alsa-plugins
              clang
              cmake
              gnuradio
              gnuradioPackages.osmosdr
              libclang
              pipewire
              pkg-config
              (rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" ];
              })
            ];

          shellHook = ''
            export PYTHONPATH="${pkgs.gnuradio}/lib/python3.11/site-packages:$PYTHONPATH"
            export ALSA_PLUGIN_DIR="${combinedAlsaPlugins}"
            LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib";
            INCLUDES_PATH="${llvmPackages.libclang.lib}/includes";
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
              pkgs.pipewire
              pkgs.alsa-lib
              pkgs.alsa-plugins
            ]}:$LD_LIBRARY_PATH
          '';
          };
        }
      );
}
