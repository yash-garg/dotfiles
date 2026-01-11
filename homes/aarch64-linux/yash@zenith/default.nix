{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace} = {
    neovim = disabled;
    starship = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.stateVersion = "26.05";
}
