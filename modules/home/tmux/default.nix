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
    aggressiveResize = !pkgs.stdenv.hostPlatform.isDarwin;
    shell = shellPath;
    shortcut = "b";
    sensibleOnTop = false;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "none"
          set -g @catppuccin_status_background "none"
          set -g @catppuccin_status_connect_separator "no"
          set -g @catppuccin_status_right_separator " "
          set -g @catppuccin_date_time_text "%H:%M"
          set -g @catppuccin_pane_border_style "fg=#{@thm_surface_1}"
          set -g @catppuccin_pane_active_border_style "fg=#{@thm_mauve}"
        '';
      }
      yank
    ];
    extraConfig = ''
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -sg escape-time 100
      set-option -g status-position bottom
      set -g status-left-length 30
      set -g status-right-length 60
      set -g status-left "#{E:@catppuccin_status_session}"
      set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_date_time}"
      set -g window-status-separator " "
      set -g window-status-format "#[fg=#313244,bg=default]#[fg=#bac2de,bg=#313244] #I #W #[fg=#313244,bg=default]#[default]"
      set -g window-status-current-format "#[fg=#cba6f7,bg=default]#[fg=#11111b,bg=#cba6f7,bold] #I #W #[fg=#cba6f7,bg=default]#[default]"

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
