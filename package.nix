{ pkgs
, coder
, version
, slim ? false
, agpl ? false
# TODO: Can we assert that this != null only when slim = false?
, frontend ? null
, ...
}:

# TODO: Enable cross compiling (it's fairly easy with Go)

let
  inherit (pkgs) buildGo119Module lib;
  inherit (pkgs.stdenv) hostPlatform;

  versionTag = "github.com/coder/coder/buildinfo.tag=${version}";
  ldflags = "-s -w -X '${versionTag}'";
  tags = if slim then [ ] else [ "embed" ];

  cmdPath = if agpl then "./cmd/coder" else "./enterprise/cmd/coder";
in
buildGo119Module {
  pname = "coder";
  inherit version;

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
  '');

  # Tests depend on having home directories etc.
  doCheck = false;
}
