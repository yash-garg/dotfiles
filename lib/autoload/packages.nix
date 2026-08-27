# lib/autoload/packages.nix
#
# Exposes every top-level directory under `packages/` as `pkgs.dots.<name>`,
# replacing snowfall-lib's package auto-discovery.
_: final: prev:
let
  root = ../../packages;
  entries = builtins.readDir root;
  names = builtins.filter (name: (entries.${name}) == "directory") (builtins.attrNames entries);
in
{
  dots = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = final.callPackage (root + "/${name}") { };
    }) names
  );
}
