{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  programs.btop = enabled // {
    settings = {
      theme_background = false;
      cpu_bottom = true;
      base_10_sizes = true;
    };
  };
}
