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
      source = lib.dots.get-file "scripts/functions";
    };

    ".aliases" = {
      executable = true;
      source = lib.dots.get-file "scripts/aliases";
    };

    ".shell-init" = {
      executable = true;
      source = lib.dots.get-file "scripts/shell-init";
    };
  };
}
