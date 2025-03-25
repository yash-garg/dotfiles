{ lib, ... }:
with lib;
{
  imports = [ ../common.nix ];

  programs.ssh.matchBlocks = {
    "github.com".identityFile = mkForce "~/.ssh/git-cf";
  };
}
