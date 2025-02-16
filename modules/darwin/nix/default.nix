{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  nix = mkNixConfig { inherit lib pkgs; } // {
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
  };
}
