{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace} = {
    atuin = enabled;
    firefox = enabled;
    kitty = enabled;
    mpv = enabled;
    neovim = enabled;
    obs = enabled;
    oh-my-posh = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.stateVersion = "26.05";
}
