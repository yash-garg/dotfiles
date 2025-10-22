{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
    sha256 = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
  };
in
{
  programs.bat = enabled // {
    themes = {
      catppuccin-mocha = {
        src = catppuccin;
        file = "themes/Catppuccin Mocha.tmTheme";
      };
      catppuccin-latte = {
        src = catppuccin;
        file = "themes/Catppuccin Latte.tmTheme";
      };
    };
    config = {
      theme = if pkgs.stdenv.isDarwin then "auto:system" else "auto";
      theme-dark = "catppuccin-mocha";
      theme-light = "catppuccin-latte";
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batwatch
    ];
  };
}
