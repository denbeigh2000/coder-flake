{ pkgs, coder, version, ... }:

let
  inherit (pkgs.yarn2nix-moretea) importOfflineCache mkYarnNix fixup_yarn_lock;
  inherit (pkgs.stdenv) mkDerivation;

  # Mostly cribbed from yarn2nix/mkYarnModules, except using package.json
  # directly instead of via a workspace.
  # https://github.com/NixOS/nixpkgs/blob/c8554deb5003c55a197effbad4b515420415e7b4/pkgs/development/tools/yarn2nix-moretea/yarn2nix/default.nix#L64
  modules =
    let
      siteFile = name: "${coder}/site/${name}";
      yarnLock = siteFile "yarn.lock";
      yarnNix = mkYarnNix { inherit yarnLock; };
      offlineCache = importOfflineCache yarnNix;

      # https://www.npmjs.com/package/canvas#user-content-compiling
      canvasDeps = with pkgs; [
        python310
        pkg-config
        pixman
        cairo
        pango
        libpng
        libjpeg
        giflib
        librsvg
      ];
    in
    mkDerivation {
      pname = "coder-site-deps";
      version = "0.0.0";

      dontUnpack = true;
      dontInstall = true;
      # Avoid this because otherwise nix tries to patch all the canvas binaries
      # of the wrong ELF type.
      dontFixup = true;
      nativeBuildInputs = with pkgs; [ yarn nodejs git ] ++ canvasDeps;

      configurePhase = ''
        export HOME="$PWD/yarn_home"
      '';

      buildPhase = ''
        cp ${yarnLock} yarn.lock
        cp ${siteFile "package.json"} package.json
        chmod +w ./yarn.lock
        yarn config --offline set yarn-offline-mirror ${offlineCache}

        ${fixup_yarn_lock}/bin/fixup_yarn_lock yarn.lock

        ${pkgs.yarn}/bin/yarn install

        mkdir $out
        mv node_modules $out
        patchShebangs $out
      '';
    };

in
mkDerivation {
  pname = "coder-site";
  version = "0.0.0";

  dontUnpack = true;
  dontInstall = true;

  src = coder;
  sourceRoot = "${coder}/site";

  buildPhase = ''
    cp -r ${coder}/site/* .
    ln -s ${modules}/node_modules node_modules
    # Because this is kept in source control, copying it from the source folder
    # keeps nix's read-only permissions.
    chmod -R ugo+rw out
    ${pkgs.yarn}/bin/yarn run build

    mkdir $out
    mv out/* $out/
  '';
}
