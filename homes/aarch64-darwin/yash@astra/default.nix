{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  imports = [ ../common.nix ];

  profiles.${namespace}.gpg = enabled;

  # We are using Yubikey for SSH
  programs.ssh.matchBlocks = {
    "github.com".identityFile = mkForce null;
  };
}
