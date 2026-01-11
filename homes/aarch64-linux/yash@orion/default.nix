{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace} = {
    oh-my-posh = enabled;
  };

  shells.${namespace}.bash = enabled;

  home.stateVersion = "26.05";
}
