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
  catppuccinDir = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin";
  # Draw the join on the window it leads into, so its background always matches
  # that window's number. No cached active index or adjacent index is needed.
  windowFormat = numberColor: "#[fg=#{?window_start_flag,#{@thm_green},#{@thm_surface_0}},bg=#{@thm_${numberColor}}]#[fg=#{@thm_crust}]#I#[fg=#{@thm_${numberColor}},bg=#{@thm_surface_0}]#[fg=#{@thm_fg}]#W#{?window_end_flag,#[fg=#{@thm_surface_0}]#[bg=#{@thm_mantle}],}#[none]";
  windowFormats = pkgs.writeText "tmux-window-formats.conf" ''
    set -g window-status-format '${windowFormat "overlay_2"}'
    set -g window-status-current-format '${windowFormat "mauve"}'
  '';
  switchCatppuccin = pkgs.writeShellScript "tmux-switch-catppuccin" ''
    case "$1" in
      light) flavor=latte ;;
      dark) flavor=mocha ;;
      *) exit 0 ;;
    esac

    palette_override="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f "$palette_override"' EXIT
    ${pkgs.gnused}/bin/sed 's/^set -ogq /set -g /' \
      "${catppuccinDir}/themes/catppuccin_''${flavor}_tmux.conf" > "$palette_override"

    ${pkgs.tmux}/bin/tmux set -g @catppuccin_flavor "$flavor"
    ${pkgs.tmux}/bin/tmux source-file "$palette_override"
    ${pkgs.tmux}/bin/tmux source-file "${catppuccinDir}/catppuccin_tmux.conf"
    ${pkgs.tmux}/bin/tmux source-file "${windowFormats}"
  '';
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
          set -g @catppuccin_window_status_style "custom"
          set -g @catppuccin_status_background "default"
          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_middle_separator "#[fg=#{@catppuccin_window_number_color},bg=#{@catppuccin_window_text_color}]"
          set -g @catppuccin_window_right_separator "#[fg=#{@catppuccin_window_text_color},bg=#{@_ctp_status_bg}]#[none]"
          set -g @catppuccin_window_current_middle_separator "#[fg=#{@catppuccin_window_current_number_color},bg=#{@catppuccin_window_current_text_color}]"
          set -g @catppuccin_window_current_right_separator "#[fg=#{@catppuccin_window_current_text_color},bg=#{@_ctp_status_bg}]#[none]"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_pane_border_style "fg=#{@thm_surface_1}"
          set -g @catppuccin_pane_active_border_style "fg=#{@thm_mauve}"
        '';
      }
      yank
    ];
    extraConfig = ''
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -sg escape-time 100
      set-option -g status-position top
      set -g status-left-length 60
      set -g status-right-length 80
      set -g status-left "#[fg=#{@thm_crust},bg=#{@thm_green}]  "
      set -g status-right "#[fg=#{@thm_surface_0},bg=#{@thm_mantle}]#[fg=#{@thm_fg},bg=#{@thm_surface_0}]  #{b:pane_current_path} #[fg=#{@thm_sapphire},bg=#{@thm_surface_0}]#[fg=#{@thm_crust},bg=#{@thm_sapphire}] 󰃰 %H:%M"
      set -g window-status-separator ""
      source-file "${windowFormats}"
      set-hook -g client-light-theme 'run-shell "${switchCatppuccin} light"'
      set-hook -g client-dark-theme 'run-shell "${switchCatppuccin} dark"'
      set-hook -g client-attached 'run-shell "${switchCatppuccin} #{client_theme}"'

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
