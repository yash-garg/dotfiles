{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.starship;
  settings = builtins.readFile ./config.toml;
in
{
  options.profiles.${namespace}.starship = {
    enable = mkEnableOption "Enable starship profile";
  };

  config = mkIf cfg.enable {
    programs.starship = enabled // {
      settings = mkMerge [
        (builtins.fromTOML settings)
      ];
    };
  };
}
