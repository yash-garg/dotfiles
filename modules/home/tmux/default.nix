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
  monokai-pro = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "monokai-pro";
    rtpFilePath = "monokai.tmux";
    version = "v0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "maxpetretta";
      repo = "tmux-monokai-pro";
      rev = "afb5831e5267047381378c41644ed46f336be33f";
      sha256 = "sha256-S6EVkjsWU6om4E8yO/g7EOToXIEka6ZuOAGwSjjEHbA=";
    };
  };
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
    plugins = with pkgs; [
      {
        plugin = monokai-pro;
        extraConfig = ''
          set -g @monokai-plugins "cpu-usage ram-usage cwd"
          set -g @monokai-refresh-rate 10
          set -g @monokai-show-battery false
          set -g @monokai-show-empty-plugins false
          set -g @monokai-show-powerline true
          set -g @monokai-transparent-powerline-bg true
        '';
      }
      tmuxPlugins.yank
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
