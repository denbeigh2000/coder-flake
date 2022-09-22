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

        # TODO: Reconsider what we want to do with this function.
        # We don't care about building containers for slim/darwin,
        # but we do care about cross-compiling slim/fat
        mkPackageSet = { slim ? false, agpl ? false, frontend ? null, slimBin ? null }:
          let
            slimFmt = if slim then "-slim" else "";
            agplFmt = if agpl then "-agpl" else "";

            package = mkPackage {
              inherit pkgs coder versionData slim agpl frontend slimBin;
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

        slimPkg = mkPackageSet { slim = true; };
        coderPkg = mkPackageSet { inherit frontend; slimBin = slimPkg.coder-slim; };

        agplSlimPkg = mkPackageSet { agpl = true; slim = true; };
        agplPkg = mkPackageSet
          {
            agpl = true;
            inherit frontend;
            slimBin = agplSlimPkg.coder-slim-agpl;
          };
      in
      {
        packages =
          (
            { inherit frontend; } //
            slimPkg // coderPkg //
            agplSlimPkg //
            agplPkg //
            { default = coderPkg; }
          );
      });
}
