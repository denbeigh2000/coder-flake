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

        versionData = import ./version.nix { inherit pkgs; };
        mkPackage = import ./package.nix;
        mkContainer = import ./container.nix;
        mkFrontend = import ./frontend.nix;

        mkPackageSet = { slim ? false, agpl ? false, frontend ? null }:
          let
            slimFmt = if slim then "-slim" else "";
            agplFmt = if agpl then "-agpl" else "";

            package = mkPackage {
              inherit pkgs coder versionData slim agpl frontend;
              inherit (versionData) version;
            };
          in
          {
            "coder${slimFmt}${agplFmt}" = package;
            "container${slimFmt}${agplFmt}" = mkContainer {
              inherit pkgs;
              inherit (versionData) tag;
              coder = package;
            };
          };

        frontend = mkFrontend {
            inherit pkgs coder;
            inherit (versionData) version;
        };
      in
      {
        packages =
          (
            { inherit frontend; } //
            mkPackageSet { inherit frontend; } //
            mkPackageSet { slim = true; } //
            mkPackageSet { agpl = true; inherit frontend; } //
            mkPackageSet { agpl = true; slim = true; } //
            { default = (mkPackageSet { inherit frontend; }).coder; }
          );
      });
}
