{
  description = "Flake providing a development shell for tt-metal playground";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nix-tt = {
      url = "github:jw910731/nix-tenstorrent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-tt,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-tt.overlays ];
        };
      in
      {
        devShells.default =
          with pkgs;
          mkShell rec {
            name = "tt-metal-playground-dev";
            nativeBuildInputs = [
              cmake
              bear
              python310
              clang
              pkg-config
            ];
            buildInputs = [
              tt-metal
              numactl
              boost
              mpi
              hwloc
            ];

            TT_METAL_RUNTIME_ROOT = "${tt-metal}/libexec/tt-metalium";
            LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
          };
      }
    );
}
