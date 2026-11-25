{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ntopng;
in
{
  options.${namespace}.services.ntopng = {
    enable = mkEnableOption "ntopng: Network Traffic Analysis";
    domain = mkOpt types.str "ipx.ovh" "The domain to serve ntopng on";
    openFirewall = mkBoolOpt true "Allow IPFIX from the configured collectors";
    collectorSources = mkOpt (types.listOf types.str) [
      "10.0.20.1"
    ] "IPv4 sources permitted to send LAN IPFIX";
    port = mkOpt types.int ports.ntopng.webui "The port for ntopng";
  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf cfg.openFirewall {
      extraInputRules = concatMapStringsSep "\n" (source: ''
        ip saddr ${source} tcp dport ${toString ports.ntopng.ipfix} accept
        ip saddr ${source} udp dport ${toString ports.ntopng.ipfix} accept
      '') cfg.collectorSources;
    };

    dots.services.backend-health.endpoints.ntopng = {
      port = cfg.port;
      statuses = [
        200
        302
      ];
    };

    services.ntopng = enabled // {
      httpPort = cfg.port;
      interfaces = [ "any" ];
      # ntopng accepts address:port, while NixOS's httpPort option is an int.
      configText = ''
        ${concatMapStringsSep "\n" (iface: "--interface=${iface}") config.services.ntopng.interfaces}
        --http-port=127.0.0.1:${toString cfg.port}
        --redis=${config.services.ntopng.redis.address}
        --data-dir=/var/lib/ntopng
        --user=ntopng
        ${config.services.ntopng.extraConfig}
      '';
      extraConfig = ''
        --community
        --collector-port=${toString ports.ntopng.ipfix}
        --local-networks="10.0.0.0/24"
      '';
    };

    dots.services.caddy.services.ntop = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
    };
  };
}
