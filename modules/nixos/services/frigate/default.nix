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

  # Frigate has no concept of Authelia users, so we disable its own auth
  # and trust the identity headers our Caddy forward_auth already injects
  # (Remote-User / Remote-Groups). Host configs can still override any of
  # this via `settings`.
  defaultSettings = {
    auth.enabled = false;
    proxy = {
      header_map = {
        user = "remote-user";
        role = "remote-groups";
      };
      default_role = "admin";
    };
  };
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
      settings = recursiveUpdate defaultSettings cfg.settings;
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
