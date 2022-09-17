{ pkgs, coder, tag }:
let
  inherit (pkgs) bash;
  etcPasswd = pkgs.writeTextDir "etc/passwd" ''
    coder:x:1000:1000::/home/coder:${bash}/bin/bash
  '';
  etcGroup = pkgs.writeTextDir "etc/group" ''
    coder:x:1000:coder
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "coder";
  tag = "v${tag}";

  fakeRootCommands = ''
    mkdir -p ./home/coder
    chown -R 1000:1000 ./home/coder
  '';

  # NOTE: Coder's original image is based on Alpine and takes care to keep the
  # those users/groups, but appears to just run the executable. It's unclear if
  # the coder binary depends on having coreutils, a shell, home dir, etc.
  contents = [ coder etcPasswd etcGroup ];

  config = {
    Entrypoint = [ "${coder}/bin/coder" "server" ];
    Environment = {
      HOME = "/home/coder";
    };
    Labels = {
      "org.opencontainers.image.title" = "Coder";
      "org.opencontainers.image.description" = "A tool for provisioning self-hosted development environments with Terraform.";
      "org.opencontainers.image.url" = "https://github.com/coder/coder";
      "org.opencontainers.image.source" = "https://github.com/coder/coder";
      "org.opencontainers.image.version" = tag;
      "org.opencontainers.image.licenses" = "AGPL-3.0";
    };
    User = "1000:1000";
    WorkingDir = "/home/coder";
  };
}
