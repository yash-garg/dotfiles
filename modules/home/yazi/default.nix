{
  lib,
  namespace,
  pkgs,
  ...
}:
with lib.${namespace};
{
  programs.yazi = enabled // {
    plugins = with pkgs.yaziPlugins; {
      catppuccin = yatline-catppuccin;
      ouch = ouch;
    };
    settings = {
      manager = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };
}
