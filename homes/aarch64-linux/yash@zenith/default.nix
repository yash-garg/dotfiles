{ lib, namespace, ... }:
with lib.${namespace};
{
  snowfallorg.user = enabled // {
    name = "yash";
  };

  profiles.${namespace} = {
    neovim = enabled;
    oh-my-posh = enabled;
  };

  shells.${namespace}.zsh = enabled;

  home.stateVersion = "24.05";
}
