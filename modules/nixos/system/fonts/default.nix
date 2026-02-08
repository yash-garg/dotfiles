{ pkgs, namespace, ... }:
{
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
}
