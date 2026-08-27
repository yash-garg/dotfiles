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
    final.lib.concatMap (name:
      let
        result = final.callPackage (root + "/${name}") { };
        # Filter out callPackage utility attributes when flattening non-derivations
        filterAttrs = builtins.filter (k: k != "override" && k != "overrideDerivation");
      in
      if final.lib.isDerivation result then
        [{ inherit name; value = result; }]
      else
        map (key: { name = key; value = result.${key}; }) (filterAttrs (builtins.attrNames result))
    ) names
  );
}
