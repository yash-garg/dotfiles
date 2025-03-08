{ lib, namespace, ... }:
with lib.${namespace};
{
  snowfallorg.user = enabled // {
    name = "yash";
  };

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

  home.stateVersion = "24.11";
}
