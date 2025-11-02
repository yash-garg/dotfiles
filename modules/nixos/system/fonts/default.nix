{ pkgs, namespace, ... }:
{
  fonts = {
    packages = with pkgs; [
      cabin
      dejavu_fonts
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
}
