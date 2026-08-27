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
          set -g @catppuccin_window_status_style "basic"
          set -g @catppuccin_status_background "none"
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
