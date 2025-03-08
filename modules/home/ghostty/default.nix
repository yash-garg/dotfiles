{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.ghostty;
in
{
  options.profiles.${namespace}.ghostty = {
    enable = mkEnableOption "ghostty, a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.";
  };

  config = mkIf cfg.enable {
    programs.ghostty = enabled // {
      package = pkgs.ghostty;
    };

    xdg.configFile."ghostty/config".source = ./config;
  };
}
