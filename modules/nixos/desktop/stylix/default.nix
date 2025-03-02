{
  config,
  pkgs,
  lib,
  inputs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.stylix;
in
{
  options.${namespace}.desktop.stylix = {
    enable = mkEnableOption "Stylix profile for desktop machines";
  };

  config = mkIf cfg.enable {
    stylix = enabled // {
      autoEnable = false;
      homeManagerIntegration.followSystem = true;
      image = ./background.png;
      base16Scheme = "${inputs.base16-schemes.outPath}/base16/monokai.yaml";
      cursor = {
        package = pkgs.rose-pine-cursor;
        name = "BreezeX-RosePine-Linux";
        size = 28;
      };
      fonts = {
        emoji = {
          name = "Noto Color Emoji";
          package = pkgs.noto-fonts-color-emoji;
        };
        monospace = {
          name = "JetBrainsMono Nerd Font Mono Regular";
          package = pkgs.nerd-fonts.jetbrains-mono;
        };
        sansSerif = {
          name = "Roboto Regular";
          package = pkgs.roboto;
        };
        serif = {
          name = "Roboto Serif 20pt Regular";
          package = pkgs.roboto-serif;
        };
        sizes = {
          applications = 12;
          terminal = 10;
        };
      };
      polarity = "dark";
      targets = {
        chromium = enabled;
        nixos-icons = enabled;
      };
    };

    snowfallorg.users.yash.home.config = {
      stylix.targets = {
        alacritty = enabled;
        bat = enabled;
        btop = enabled;
        fzf = enabled;
        vesktop = enabled;
        wezterm = enabled;
        yazi = enabled;
        zellij = enabled;
      };
    };
  };
}
