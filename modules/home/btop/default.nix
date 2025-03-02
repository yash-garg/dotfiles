{
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  programs.btop = enabled // {
    settings = {
      color_theme = lib.mkForce "${pkgs.btop}/share/btop/themes/monokai.theme";
      theme_background = false;
      cpu_bottom = true;
      base_10_sizes = true;
    };
  };
}
