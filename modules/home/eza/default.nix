{ lib, namespace, ... }:
with lib.${namespace};
{
  programs.eza = enabled // {
    icons = null;
    extraOptions = [ "--all" ];
  };
}
