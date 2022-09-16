{
  description = "A derivation for Coder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    coder = {
      url = "github:coder/coder";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, coder }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      mkCoder = import ./build.nix;
    in
      with pkgs; {
        packages = {
          coder = mkCoder {
            inherit pkgs coder;
            version = "0.8.15";
          };
        };
      });
}
