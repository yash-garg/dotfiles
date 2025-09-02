{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace} = {
    neovim = disabled;
    oh-my-posh = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.stateVersion = "24.05";
}
