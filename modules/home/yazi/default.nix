{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  programs.yazi = enabled // {
    settings = {
      manager = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };
}
