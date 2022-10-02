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

  mkBinary = { GOOS, GOARCH, GOARM ? "" }:
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
      inherit GOOS GOARCH GOARM;

      vendorSha256 = "sha256-qWjRr2s6hc5+ywJK05M3LxUeKZ9L0107QH5h0nqaFSY=";
      preBuild = ''
        export GOOS="${GOOS}"
        export GOARCH="${GOARCH}"
        export GOARM="${GOARM}"
        subPackages="${cmdPath}"
      '';

      postInstall = ''
        # TODO: version is currently not upstream-accurate
        OUT_FILE=$out/bin/coder_${version}_$GOOS_$GOARCH${suffix}
        find $out/bin -type f | xargs -I{} mv {} $OUT_FILE
        find $out -mindepth 2 -type d | xargs rm -rf
      '';
    };

  mkGroup = paths:
    pkgs.symlinkJoin {
      name = "coder-slim-all";
      inherit paths;
    };

  mkTarball = group:
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
        cd ${group}/bin
        tar \
          --use-compress-program "zstd -T0 -22 --ultra" \
          --create \
          --keep-old-files \
          --dereference \
          --file=$out/coder-slim_${version}.tar.zst \
          ./*
      '';
    };

  mkChecksum = group:
    pkgs.stdenvNoCC.mkDerivation {
      name = "slim-tarball-checksum";
      buildInputs = [ group ];

      dontUnpack = true;
      dontInstall = true;

      src = group;

      buildPhase = ''
        mkdir $out
        cd ${group}/bin
        ${pkgs.openssl}/bin/openssl dgst -r -sha1 coder* > $out/coder.sha1
      '';
    };

  group = mkGroup [
    (mkBinary { GOOS = "linux"; GOARCH = "amd64"; })
    (mkBinary { GOOS = "linux"; GOARCH = "arm64"; })
    (mkBinary { GOOS = "linux"; GOARCH = "arm"; GOARM = "7"; })
    (mkBinary { GOOS = "darwin"; GOARCH = "amd64"; })
    (mkBinary { GOOS = "darwin"; GOARCH = "arm64"; })
    (mkBinary { GOOS = "windows"; GOARCH = "amd64"; })
    (mkBinary { GOOS = "windows"; GOARCH = "arm64"; })
  ];
in
{
  checksum = mkChecksum group;
  tarball = mkTarball group;
}
