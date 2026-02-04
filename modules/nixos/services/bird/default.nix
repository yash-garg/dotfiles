{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.bird;
in
{
  options.${namespace}.services.bird = {
    enable = mkEnableOption "Bird: Internet Routing Daemon";
  };

  config = mkIf cfg.enable {
    services.bird = enabled // {
      autoReload = true;
      checkConfig = true;
      config = readFile ./bird.conf;
    };
  };
}
