{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.frigate;
in
{
  options.${namespace}.services.frigate = {
    enable = mkEnableOption "frigate: NVR for IP cameras";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the frigate service";
    settings = mkOpt types.attrs { } "Frigate configuration settings";
    environmentFile = mkOpt (types.nullOr types.path) null "Environment file containing secrets";
    port = mkOpt types.int ports.frigate "The port for frigate";
  };

  config = mkIf cfg.enable {
    services.frigate = enabled // {
      inherit (cfg) settings;
      checkConfig = false;
      hostname = "0.0.0.0";
    };

    dots.services.caddy.services.nvr = {
      inherit (cfg) domain;
      upstream = "0.0.0.0:${toString cfg.port}";
      auth = true;
    };

    systemd.services.frigate = mkIf (cfg.environmentFile != null) {
      serviceConfig.EnvironmentFile = cfg.environmentFile;
    };
  };
}
