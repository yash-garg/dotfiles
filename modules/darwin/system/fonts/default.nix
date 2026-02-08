{ pkgs, namespace, ... }:
{
  fonts = {
    packages = with pkgs; [
      cabin
      nerd-fonts.caskaydia-cove
      nerd-fonts.iosevka-term
      nerd-fonts.jetbrains-mono
      maple-mono.variable
      maple-mono.NF
      pkgs.${namespace}.monolisa-nerdfonts
    ];
  };
}
