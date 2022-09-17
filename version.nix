{ pkgs }:

let
  inherit (builtins) fromJSON readFile substring;
  inherit (pkgs.lib.strings) removePrefix;

  lock = fromJSON (readFile ./flake.lock);
  coderLock = lock.nodes.coder;
  tag = removePrefix "v" (coderLock.original.ref or "devel");
  sha = substring 0 7 coderLock.locked.rev;

in
  "${tag}+${sha}"
