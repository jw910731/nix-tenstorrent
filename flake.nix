{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: function (import nixpkgs { inherit system; }));
      packages = pkgs: {
        tt-metal = pkgs.callPackage ./tt-metal.nix { };
        tt-flash = pkgs.callPackage ./tt-flash.nix { };
      };
    in
    {
      overlays = final: prev: (packages final);
      packages = forAllSystems packages;
    };
}
