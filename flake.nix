{
  description = "A derivation for Coder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    coder = {
      url = "github:coder/coder/v0.8.15";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, coder }:
    # TODO: Coder currently builds for arm archs that aren't included here.
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = import ./version.nix { inherit pkgs; };
        mkPackage = import ./package.nix;
        mkContainer = import ./container.nix;
      in
      with pkgs; {
        packages = rec {
          coder-fat = mkCoder { inherit pkgs coder version; };
          container = mkContainer {
            inherit pkgs version;
            coder = coder-fat;
          };
          coder-slim = mkCoder {
            inherit pkgs coder version;
            slim = true;
          };
          coder-agpl = mkCoder {
            inherit pkgs coder version;
            agpl = true;
          };
          coder-slim-agpl = mkCoder {
            inherit pkgs coder version;
            slim = true;
            agpl = true;
          };
        };
      });
}
