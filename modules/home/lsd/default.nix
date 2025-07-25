{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.lsd;
in
{
  options.profiles.${namespace}.lsd = {
    enable = mkEnableOption "Enable lsd profile";
  };

  config = mkIf cfg.enable {
    programs.lsd = enabled // {
      enableAliases = true;
      settings = {
        date = "relative";
        icons.when = "never";
      };
    };
  };
}
