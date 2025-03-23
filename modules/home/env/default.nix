{ lib, ... }:
with lib;
{
  home.file = {
    ".nanorc".text = ''
      set tabsize 4
      set autoindent
      set softwrap
      set nonewlines
      set smarthome
    '';

    ".functions" = {
      executable = true;
      source = snowfall.fs.get-file "scripts/functions";
    };

    ".aliases" = {
      executable = true;
      source = snowfall.fs.get-file "scripts/aliases";
    };

    ".shell-init" = {
      executable = true;
      source = snowfall.fs.get-file "scripts/shell-init";
    };
  };
}
