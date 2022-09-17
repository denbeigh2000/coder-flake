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
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs.lib.strings) removePrefix;
      inherit (builtins) fromJSON readFile substring;

      lock = fromJSON (readFile ./flake.lock);
      coderLock = lock.nodes.coder;
      tag = removePrefix "v" (coderLock.original.ref or "devel");
      sha = substring 0 8 coderLock.locked.rev;
      version = "${tag}+${sha}";

      mkCoder = import ./build.nix;
    in
      with pkgs; {
        packages = {
          coder = mkCoder { inherit pkgs coder version; };
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
