{
  pkgs,
  lib,
  config,

  namespace,
  ...
}:
with lib.${namespace};
{
  dots.user = enabled // {
    inherit (config.snowfallorg.user) name;
  };

  profiles.${namespace} = {
    atuin = enabled;
    neovim = enabled;
    oh-my-posh = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.packages = with pkgs; [
    apktool
    nh-darwin
    nix-output-monitor
    scrcpy
  ];

  home.stateVersion = "24.11";
}
