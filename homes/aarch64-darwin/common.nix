{
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  profiles.${namespace} = {
    atuin = enabled;
    neovim = enabled;
    starship = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.packages = with pkgs; [
    apktool
    nix-output-monitor
    scrcpy
  ];

  home.stateVersion = "24.11";
}
