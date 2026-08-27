# lib/autoload/tree.nix
#
# Recursively find every `default.nix` file under `dir`, at any depth,
# and return them as a list of paths. Used to auto-import modules and
# overlays by folder convention, replacing snowfall-lib's module
# auto-discovery.
{ lib }:
dir:
let
  walk =
    relPath:
    let
      full = if relPath == "" then dir else dir + "/${relPath}";
      entries = builtins.readDir full;
      collect =
        name: type:
        let
          path = if relPath == "" then name else "${relPath}/${name}";
        in
        if type == "directory" then
          walk path
        else if name == "default.nix" && relPath != "" then
          [ (dir + "/${path}") ]
        else
          [ ];
    in
    lib.flatten (lib.mapAttrsToList collect entries);
in
walk ""
