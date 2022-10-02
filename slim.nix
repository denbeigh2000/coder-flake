{ nixpkgs
, coder
, version
, system
, agpl ? false
, ...
}:

let
  # TODO: DRY, define these tags somewhere else.
  versionTag = "github.com/coder/coder/buildinfo.tag=${version}";
  ldflags = "-s -w -X '${versionTag}'";
  cmdPath = if agpl then "./cmd/coder" else "./enterprise/cmd/coder";

  pkgs = import nixpkgs { inherit system; };

  mkBinary = { GOOS, GOARCH }:
    let
      # TODO: Can we make use of cross-compiling without manually overriding
      # GOOS/GOARCH? Setting crossSystem makes nix try to compile all
      # toolchains from scratch, which opens a can of worms.
      # We don't explicitly use a cross-compiled version here, because
      # that wants to compile
      pkgs = import nixpkgs {
        # inherit crossSystem;
        inherit system;
      };

      suffix = if GOOS == "windows" then ".exe" else "";
    in
    pkgs.buildGo119Module {
      pname = "coder-slim";
      inherit version;

      doCheck = false;

      src = coder;

      inherit ldflags;
      CGO_ENABLED = 0;

      # NOTE: These get overridden if not manually specified in preBuild
      inherit GOOS GOARCH;

      nativeBuildInputs = [ pkgs.go_1_19 ];

      vendorSha256 = "sha256-qWjRr2s6hc5+ywJK05M3LxUeKZ9L0107QH5h0nqaFSY=";
      preBuild = ''
        export GOOS="${GOOS}"
        export GOARCH="${GOARCH}"
        subPackages="${cmdPath}"
      '';

      postInstall = ''
        # TODO: version is currently not upstream-accurate
        find $out/bin -type f | xargs -I{} mv {} $out/bin/coder_${version}_$GOOS_$GOARCH${suffix}
      '';
    };

    mkTarball = paths:
    let
      combined = pkgs.symlinkJoin {
        name = "coder-slim-all";
        inherit paths;
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "coder-tarball";
      inherit version;
      dontUnpack = true;
      dontInstall = true;
      dontFixup = true;

      buildInputs = [ pkgs.zstd pkgs.gnutar ];

      # TODO: Add SHASUMS here, too
      buildPhase = ''
      mkdir $out
      tar \
        --directory=${combined}/bin \
        --use-compress-program "zstd -T0 -22 --ultra" \
        --create \
        --keep-old-files \
        --dereference \
        --file=$out/coder-slim_${version}.tar.zst \
        .
      '';
    };
in
  mkTarball [
    (mkBinary {GOOS = "linux"; GOARCH = "amd64";})
    (mkBinary {GOOS = "linux"; GOARCH = "arm64";})
    (mkBinary {GOOS = "linux"; GOARCH = "arm";})
    (mkBinary {GOOS = "darwin"; GOARCH = "amd64";})
    (mkBinary {GOOS = "darwin"; GOARCH = "arm64";})
    (mkBinary {GOOS = "windows"; GOARCH = "amd64";})
    (mkBinary {GOOS = "windows"; GOARCH = "arm64";})
  ]
