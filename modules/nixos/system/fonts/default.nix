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
  cfg = config.${namespace}.system.fonts;
in
{
  options.${namespace}.system.fonts = {
    enable = mkEnableOption "System fonts configuration";
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        cabin
        dejavu_fonts
        maple-mono.variable
        maple-mono.NF
        pkgs.${namespace}.monolisa-nerdfonts
        nerd-fonts.caskaydia-cove
        nerd-fonts.iosevka-term
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        unifont
      ];
    };
  };
}
