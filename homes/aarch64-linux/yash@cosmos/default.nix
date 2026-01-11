{ lib, namespace, ... }:
with lib.${namespace};
{
  profiles.${namespace}.starship = enabled;

  shells.${namespace}.bash = enabled;

  home.stateVersion = "26.05";
}
