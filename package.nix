{ pkgs
, coder
, version
, slim ? false
, agpl ? false
, ...
}:

# TODO: Enable cross compiling (it's fairly easy with Go)

let
  inherit (pkgs) buildGo119Module;
  inherit (pkgs.stdenv) hostPlatform mkDerivation;

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
  '';

  # Tests depend on having home directories etc.
  doCheck = false;
}
