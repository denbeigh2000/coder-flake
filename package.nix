{ pkgs
, coder
, version
, frontend
, slim
, GOOS
, GOARCH
, GOARM ? ""
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

  inherit GOOS GOARCH GOARM;

  vendorSha256 = "sha256-qWjRr2s6hc5+ywJK05M3LxUeKZ9L0107QH5h0nqaFSY=";

  # NOTE: We can't improve compilation re-use by building both enterprise
  # and non-enterprise here, because they both output binaries called "coder",
  # and one overwrites the other.
  preBuild = ''
    subPackages="${cmdPath}"
    rm -rf site/out
    mkdir -p site/out/bin
    cp -r ${frontend}/* site/out/
    cp ${slim.tarball}/coder-slim_${version}.tar.zst site/out/bin/coder.tar.zst
    cp ${slim.checksum}/coder.sha1 site/out/bin/coder.sha1
    export GOOS=${GOOS}
    export GOARCH=${GOARCH}
    export GOARM=${GOARM}
  '';

  # TODO: Generate a shasum and add it to $out/
  # TODO: The output binary should contain a version
  postInstall = ''
    OUT_FILE=$out/bin/coder_${version}_$GOOS_$GOARCH${suffix}
    find $out/bin -type f | xargs -I{} mv {} $OUT_FILE
    ${pkgs.openssl}/bin/openssl dgst -r -sha1 > $OUT_FILE.sha1
  '';
}
