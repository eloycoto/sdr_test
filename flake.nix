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

        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = with pkgs; [
              gnuradio
              gnuradioPackages.osmosdr
              cmake
              pkg-config
            ];

          shellHook = ''
            export PYTHONPATH="${pkgs.gnuradio}/lib/python3.11/site-packages:$PYTHONPATH"
          '';
          };
        }
      );
}
