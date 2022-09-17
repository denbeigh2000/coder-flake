{ pkgs, coder, version }:
let

in
pkgs.dockerTools.buildImage {
  name = "coder";
  uid = 1000;
  gid = 1000;
  config = {
    Entrypoint = [ "${coder}/bin/coder" ];
  };
}
