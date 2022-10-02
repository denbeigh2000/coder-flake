{ pkgs }:

# TODO: The original differentiates between a "devel" option with the sha
# appended, and a real release versionsha appended, and a X.Y.Z semver tag.
# We're doing a weird mishmash of both

let
  inherit (builtins) fromJSON readFile substring;
  inherit (pkgs.lib.strings) removePrefix;

  lock = fromJSON (readFile ./flake.lock);
  coderLock = lock.nodes.coder;
  tag = removePrefix "v" (coderLock.original.ref or "devel");
  sha = substring 0 7 coderLock.locked.rev;

  version = if tag == "devel" then "devel-${sha}" else tag;
in
{
  inherit tag sha version;
}
