{ pkgs
, coder
, version
, slim ? false
, agpl ? false
  # TODO: Can we assert that these != null only when slim = false?
, frontend ? null
, slimBin ? null
, ...
}:

# TODO: Enable cross compiling (it's fairly easy with Go)

let
  inherit (pkgs) buildGo119Module lib zstd;
  inherit (pkgs.stdenv) hostPlatform mkDerivation;

  versionTag = "github.com/coder/coder/buildinfo.tag=${version}";
  ldflags = "-s -w -X '${versionTag}'";
  tags = if slim then [ ] else [ "embed" ];

  cmdPath = if agpl then "./cmd/coder" else "./enterprise/cmd/coder";

  slimTarball = mkDerivation {
    pname = "coder-slim-tarball";
    inherit version;

    dontUnpack = true;
    dontInstall = true;
    dontFixup = true;

    # TODO: The original first builds slim for all platforms, bundles them into
    # this tarball, and embeds that into the fat binary - we're only doing that
    # for this platform.
    # TODO: Shasums
    buildPhase = ''
      mkdir $out
      # TODO: Coder expects this name to have a version
      tar -C ${slimBin}/bin -ckf $out/coder-slim_${version}.tar coder
    '';
  };

  compressedSlimBin = mkDerivation {
    pname = "compressed-coder-slim";
    inherit version;

    dontUnpack = true;
    dontInstall = true;
    dontFixup = true;

    buildPhase = ''
      mkdir $out
      ${pkgs.zstd}/bin/zstd --force --long --no-progress --keep \
        ${slimTarball}/coder-slim_${version}.tar \
        -o $out/coder-slim_${version}.tar.zst
    '';
  };

in
buildGo119Module {
  pname = "coder";
  inherit version;

  # Tests depend on having home directories etc.
  doCheck = false;

  src = coder;

  inherit ldflags tags;
  CGO_ENABLED = 0;

  vendorSha256 = "sha256-MxCvcjg771W0wyCn76gKCuAQ2cQgvo/4Z8aVk5gWHoc=";

  # NOTE: We can't improve compilation re-use by building both enterprise
  # and non-enterprise here, because they both output binaries called "coder",
  # and one overwrites the other.
  preBuild = ''
    subPackages="${cmdPath}"
  '' + (lib.optionalString (!slim) ''
    rm -rf site/out
    mkdir site/out
    cp -r ${frontend}/* site/out/
    cp ${compressedSlimBin}/coder-slim_${version}.tar.zst site/out/coder.tar.zst
  '');

  # TODO: Generate a shasum and add it to $out/
  # TODO: The output binary should contain a version
  # postBuild = '' '';
}
