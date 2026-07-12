{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  imports = [ ../common.nix ];

  programs.ssh.settings = {
    "github.com".IdentityFile = mkForce null;
  };
}
