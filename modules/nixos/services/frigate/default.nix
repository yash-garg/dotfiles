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

    # Frigate's NixOS module fronts everything (auth_request, HLS, thumbnails,
    # websockets, etc.) with its own nginx vhost. By default that vhost tries
    # to bind 0.0.0.0:80/443, which collides with our host-wide Caddy. Pin it
    # to a private loopback port instead and have Caddy reverse_proxy to that.
    services.nginx.virtualHosts."0.0.0.0".listen = [
      {
        addr = "127.0.0.1";
        port = cfg.port;
      }
    ];

    dots.services.caddy.services.nvr = {
      inherit (cfg) domain;
      upstream = "127.0.0.1:${toString cfg.port}";
      auth = true;
    };

    systemd.services.frigate = mkIf (cfg.environmentFile != null) {
      serviceConfig.EnvironmentFile = cfg.environmentFile;
    };
  };
}
