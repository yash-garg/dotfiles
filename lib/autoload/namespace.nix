# lib/autoload/namespace.nix
#
# Extends `lib` with `lib.dots`, replicating snowfall-lib's namespace
# merging: every `lib/<name>/default.nix` file's top-level attrs are
# flattened together under `lib.dots`, plus a `get-file` helper that
# replaces `snowfall.fs.get-file`.
{ lib }:
let
  root = ../..;

  custom = lib.foldl' lib.recursiveUpdate { } [
    (import ../module { inherit lib; })
    (import ../ports)
    (import ../trusted-proxies)
    (import ../nix-config)
  ];
in
lib.extend (
  final: _prev: {
    dots = custom // {
      get-file = relPath: root + "/${relPath}";
    };
  }
)
