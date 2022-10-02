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

        mkCoder = {GOOS, GOARCH}:
          mkPackage {
            inherit coder pkgs frontend slim GOOS GOARCH;
            inherit (versionData) version;
            agpl = true;
          };

      in
      {
        packages = {
          inherit (slim) tarball;
          inherit (slim) checksum;
          coder-linux-arm64 = mkCoder { GOOS = "linux"; GOARCH = "amd64"; };
          coder-linux-amd64 = mkCoder { GOOS = "linux"; GOARCH = "amd64"; };
          coder-linux-arm = mkCoder { GOOS = "linux"; GOARCH = "arm"; };
          coder-darwin-arm64 = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; };
          coder-darwin-amd64 = mkCoder { GOOS = "darwin"; GOARCH = "amd64"; };
          coder-windows-arm64 = mkCoder { GOOS = "windows"; GOARCH = "amd64"; };
          coder-windows-amd64 = mkCoder { GOOS = "windows"; GOARCH = "amd64"; };
          # coder = mkPackage {
          #   inherit coder pkgs frontend slimEmbed;
          #   inherit (versionData) version;
          #   agpl = true;
          # };
        };
      });
}
