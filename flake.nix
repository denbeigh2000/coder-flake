{
  description = "A derivation for Coder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    coder = {
      url = "github:coder/coder/v0.9.1";
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

        slim = import ./slim.nix {
          inherit system nixpkgs coder;
          inherit (versionData) version;
          agpl = true;
        };

        frontend = mkFrontend {
          inherit pkgs coder;
          inherit (versionData) version;
        };

        mkCoder = {GOOS, GOARCH, agpl ? false}:
          mkPackage {
            inherit agpl coder pkgs frontend slim GOOS GOARCH;
            inherit (versionData) version;
          };

      in
      {
        packages = rec {
          container = mkContainer {
            inherit pkgs;
            inherit (versionData) tag;
            coder = coder-linux-amd64;
          };
          coder-linux-arm64 = mkCoder { GOOS = "linux"; GOARCH = "amd64"; };
          coder-linux-amd64 = mkCoder { GOOS = "linux"; GOARCH = "amd64"; };
          coder-linux-arm = mkCoder { GOOS = "linux"; GOARCH = "arm"; };
          coder-darwin-arm64 = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; };
          coder-darwin-amd64 = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; };
          coder-windows-arm64 = mkCoder { GOOS = "windows"; GOARCH = "amd64"; };
          coder-windows-amd64 = mkCoder { GOOS = "windows"; GOARCH = "amd64"; };

          coder-linux-arm64-agpl = mkCoder { GOOS = "linux"; GOARCH = "amd64"; agpl = true; };
          coder-linux-amd64-agpl = mkCoder { GOOS = "linux"; GOARCH = "amd64"; agpl = true; };
          coder-linux-arm-agpl = mkCoder { GOOS = "linux"; GOARCH = "arm"; agpl = true; };
          coder-darwin-arm64-agpl = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; agpl = true; };
          coder-darwin-amd64-agpl = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; agpl = true; };
          coder-windows-arm64-agpl = mkCoder { GOOS = "windows"; GOARCH = "amd64"; agpl = true; };
          coder-windows-amd64-agpl = mkCoder { GOOS = "windows"; GOARCH = "amd64"; agpl = true; };
        };
      });
}
