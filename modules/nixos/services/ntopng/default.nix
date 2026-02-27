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
    openFirewall = mkBoolOpt false "Open the firewall for ntopng";
    port = mkOpt types.int ports.ntopng.webui "The port for ntopng";
  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.port
        ports.ntopng.ipfix
      ];
      allowedUDPPorts = [ ports.ntopng.ipfix ];
    };

    services.ntopng = enabled // {
      httpPort = cfg.port;
      interfaces = [ "any" ];
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
