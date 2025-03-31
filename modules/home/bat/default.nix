{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  programs.bat = enabled // {
    config.theme = lib.mkForce "ansi";
    extraPackages = with pkgs.bat-extras; [
      batgrep
      batman
    ];
  };
}
