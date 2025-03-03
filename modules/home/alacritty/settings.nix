{ lib, ... }:
{
  programs.alacritty.settings = {
    env = {
      TERM = "xterm-256color";
    };

    font = lib.mkForce {
      size = 14;

      normal = {
        family = "CaskaydiaCove Nerd Font Mono";
        style = "Regular";
      };

      bold = {
        family = "CaskaydiaCove Nerd Font Mono";
        style = "Bold";
      };

      bold_italic = {
        family = "CaskaydiaCove Nerd Font Mono";
        style = "Bold Italic";
      };

      italic = {
        family = "CaskaydiaCove Nerd Font Mono";
        style = "Italic";
      };
    };

    selection.save_to_clipboard = true;

    window = {
      dynamic_padding = true;
      startup_mode = "Windowed";

      dimensions = {
        columns = 160;
        lines = 45;
      };

      padding = {
        x = 16;
        y = 16;
      };
    };
  };
}
