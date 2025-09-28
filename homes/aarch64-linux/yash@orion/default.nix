{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace} = {
    oh-my-posh = enabled;
  };

  shells.${namespace}.bash = enabled;

  home.stateVersion = "25.05";
}
