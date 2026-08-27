# modules/home/user/default.nix
{ pkgs, homeUsername, ... }:
{
  home = {
    username = homeUsername;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${homeUsername}" else "/home/${homeUsername}";
  };
}
