{
  description = "Langchain flake with tools";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    eloy.url = "github:eloycoto/nix-custom-overlay";
  };
  outputs = { self, nixpkgs, flake-utils, eloy }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [eloy.overlays.default];
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
              gnuradio
              gnuradioPackages.osmosdr
              cmake
              pkg-config
              pipewire
              alsa-lib
              alsa-plugins
            ];

          shellHook = ''
            export PYTHONPATH="${pkgs.gnuradio}/lib/python3.11/site-packages:$PYTHONPATH"
            export ALSA_PLUGIN_DIR="${combinedAlsaPlugins}"
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
