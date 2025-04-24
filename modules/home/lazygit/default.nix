{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.lazygit = enabled // {
    settings = {
      git.autoFetch = false;
      gui = {
        paging.useConfig = true;
        showBottomLine = false;
        showCommandLog = false;
        showRandomTip = false;
        theme.selectedLineBgColor = [ "black" ];
      };
    };
  };
}
