{ pkgs
, coder
, version
, frontend
, slimEmbed
, GOOS
, GOARCH
, agpl ? false
, ...
}:

let
  inherit (pkgs) buildGo119Module lib zstd;
  inherit (pkgs.stdenv) hostPlatform mkDerivation;

  versionTag = "github.com/coder/coder/buildinfo.tag=${version}";
  ldflags = "-s -w -X '${versionTag}'";

  cmdPath = if agpl then "./cmd/coder" else "./enterprise/cmd/coder";

  suffix = if GOOS == "windows" then ".exe" else "";
in
buildGo119Module {
  pname = "coder";
  inherit version;

  # Tests depend on having home directories etc.
  doCheck = false;

  src = coder;

  inherit ldflags;
  tags = [ "embed" ];
  CGO_ENABLED = 0;

  vendorSha256 = "sha256-qWjRr2s6hc5+ywJK05M3LxUeKZ9L0107QH5h0nqaFSY=";

  # NOTE: We can't improve compilation re-use by building both enterprise
  # and non-enterprise here, because they both output binaries called "coder",
  # and one overwrites the other.
  preBuild = ''
    subPackages="${cmdPath}"
    rm -rf site/out
    mkdir site/out
    cp -r ${frontend}/* site/out/
    cp ${slimEmbed}/coder-slim_${version}.tar.zst site/out/coder.tar.zst
    export GOOS=${GOOS}
    export GOARCH=${GOARCH}
  '';

  # TODO: Generate a shasum and add it to $out/
  # TODO: The output binary should contain a version
  postInstall = ''
    find $out/bin -type f | xargs -I{} mv {} $out/bin/coder_${version}_$GOOS_$GOARCH${suffix}
  '';
}
