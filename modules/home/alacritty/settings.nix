{ lib, ... }:
{
  programs.alacritty.settings = {
    env = {
      TERM = "xterm-256color";
    };

    font = lib.mkForce {
      size = 17;

      normal = {
        family = "Maple Mono NF";
        style = "Regular";
      };

      bold = {
        family = "Maple Mono NF";
        style = "Bold";
      };

      bold_italic = {
        family = "Maple Mono NF";
        style = "Bold Italic";
      };

      italic = {
        family = "Maple Mono NF";
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
