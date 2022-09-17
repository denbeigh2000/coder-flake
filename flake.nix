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

        mkPackageSet = { slim ? false, agpl ? false }:
          let
            slimFmt = if slim then "-slim" else "";
            agplFmt = if agpl then "-agpl" else "";

            package = mkPackage { inherit pkgs coder version slim agpl; };
          in
          {
            "coder${slimFmt}${agplFmt}" = package;
            "container${slimFmt}${agplFmt}" = mkContainer {
              inherit pkgs version;
              coder = package;
            };
          };
      in
      {
        packages =
          (
            mkPackageSet { } //
            mkPackageSet { slim = true; } //
            mkPackageSet { agpl = true; } //
            mkPackageSet { agpl = true; slim = true; } //
            { default = (mkPackageSet { }).coder; }
          );
      });
}
