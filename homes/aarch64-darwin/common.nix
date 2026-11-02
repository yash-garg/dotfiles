{
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  profiles.${namespace} = {
    neovim = enabled;
    starship = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.packages = with pkgs; [
    apktool
    nix-output-monitor
    rustup
    scrcpy
  ];

  home.stateVersion = "26.05";
}
