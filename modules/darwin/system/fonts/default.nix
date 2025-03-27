{ pkgs, namespace, ... }:
{
  fonts = {
    packages = with pkgs; [
      cabin
      nerd-fonts.caskaydia-cove
      nerd-fonts.jetbrains-mono
      pkgs.${namespace}.monolisa-nerdfonts
    ];
  };
}
