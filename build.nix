{ pkgs
, coder
, version
, slim ? false
, agpl ? false
, ...
}:

let
  inherit (pkgs.stdenv) hostPlatform mkDerivation;

  go = pkgs.go_1_19;

  versionTag = "github.com/coder/coder/buildinfo.tag=${version}";
  ldFlags = "\"-s -w -X '${versionTag}'\"";

  buildArgs = "-ldflags ${ldFlags} "
    + (if slim then " -tags embed" else "");

  # Windows ¯\_(ツ)_/¯
  goOs = if hostPlatform.isLinux then "linux" else "darwin";
  goArchValues = {
    x86_64 = "amd64";
    aarch64 = "arm64";
    # TODO: Other arm architectures??
  };

  goArch = goArchValues.${hostPlatform.linuxArch};

  cmdPath = if agpl then "./cmd/coder" else "./enterprise/cmd/coder";
in
mkDerivation {
  name = "coder";
  inherit version;

  src = coder;

  buildInputs = with pkgs; [ stdenv go glibc.static ];

  phases = [ "buildPhase" ];
  # TODO: Support cross-compiling?
  buildPhase = ''
    export GOARCH="$(${go}/bin/go env GOARCH)"
    export GOOS="$(${go}/bin/go env GOOS)"
    export GOARM="$(${go}/bin/go env GOARM)"

    cd ${coder}
    export HOME="$(mktemp -d)"
    CGO_ENABLED=0 go build -o $out/bin/coder ${buildArgs} ${cmdPath}
  '';
}
