# modules/home/user/default.nix
{ lib, pkgs, homeUsername, ... }:
{
  # home-manager's own nixos/common.nix module (shared by nixosModules.home-manager
  # and darwinModules.home-manager) also assigns `home.username`/`home.homeDirectory`
  # at plain priority, derived from `config.users.users.<name>.{name,home}`. On hosts
  # that don't explicitly set `users.users.<name>.home` (e.g. nix-darwin hosts), that
  # resolves to null and conflicts with our own plain assignment. Use mkForce so our
  # explicit value always wins regardless of whether the system sets it too.
  home = {
    username = lib.mkForce homeUsername;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${homeUsername}" else "/home/${homeUsername}"
    );
  };
}
