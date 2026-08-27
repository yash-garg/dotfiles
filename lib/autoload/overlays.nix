# lib/autoload/overlays.nix
#
# Collects every `overlays/*/default.nix` (each shaped as
# `inputs: final: prev: {...}`) and applies `inputs`, producing a plain
# list of `final: prev: {...}` overlays. Replaces snowfall-lib's
# overlay auto-discovery.
{ lib, inputs }:
let
  tree = import ./tree.nix { inherit lib; };
  files = tree ../../overlays;
in
map (file: (import file) inputs) files
