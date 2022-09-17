# coder-flake

[Coder](https://github.com/coder/coder), packaged as a Nix flake.

## Outputs

 - Binaries:

   - coder: Default release with enterprise features.
   - coder-agpl: Only AGPL-licensed features (no enterprise features).
   - coder-slim: "Slim" release.
   - coder-slim-agpl: "Slim" release with no only AGPL-licensed features.

 - Containers with the above binaries:

   - container
   - container-agpl
   - container-slim
   - container-slim-agpl

## TODO
 - Add support for Cross-compilation
 - Add NixOS module for running the server
