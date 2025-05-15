{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  imports = [ ../common.nix ];

  programs.ssh.matchBlocks = {
    "github.com".identityFile = mkForce null;
  };
}
