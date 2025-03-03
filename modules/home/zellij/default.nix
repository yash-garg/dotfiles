{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.zellij;
in
{
  options.profiles.${namespace}.zellij = {
    enable = mkEnableOption "Enable zellij profile";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zjstatus ];

    programs.zellij = enabled // {
      settings = {
        mouse_mode = true;
        on_force_close = "detach";
        scroll_buffer_size = 100000;
        simplified_ui = false;
        ui.pane_frames = {
          hide_session_name = false;
          rounded_corners = true;
        };
      };
    };

    xdg.configFile.zellijLayouts = {
      source = ./layouts;
      target = "./zellij/layouts";
    };
  };
}
