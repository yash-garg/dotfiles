{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
let
  shellPath = if config.shells.${namespace}.bash.enable then null else "${pkgs.zsh}/bin/zsh";
in
{
  programs.tmux = enabled // {
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    aggressiveResize = !pkgs.stdenv.isDarwin;
    shell = shellPath;
    shortcut = "b";
    sensibleOnTop = false;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator " "
          set -g @catppuccin_window_middle_separator " █"
          set -g @catppuccin_window_number_position "right"

          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_default_text "#W"

          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#W"

          set -g @catppuccin_status_background "default"
          set -g @catppuccin_status_modules_right "directory session"
          set -g @catppuccin_status_left_separator  " "
          set -g @catppuccin_status_right_separator ""
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"

          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
      yank
    ];
    extraConfig = ''
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -sg escape-time 100
      set-option -g status-position bottom

      # Key Bindings
      unbind c
      unbind p
      bind n new-window
      bind p split-window -h
      bind-key Right next-window
      bind-key Left previous-window
    '';
  };
}
