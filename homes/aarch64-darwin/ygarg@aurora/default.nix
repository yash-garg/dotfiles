{ lib, ... }:
with lib;
{
  imports = [ ../common.nix ];

  programs.ssh.settings = {
    "github.com".IdentityFile = mkForce "~/.ssh/git-work";
  };
}
