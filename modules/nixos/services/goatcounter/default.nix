{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.goatcounter;
in
{
  options.${namespace}.services.goatcounter = {
    enable = mkEnableOption "GoatCounter web analytics";
    domain = mkOpt types.str "yashgarg.dev" "Domain to serve GoatCounter on (as stats.<domain>)";
    port = mkOpt types.int ports.goatcounter "Port for GoatCounter";
    openFirewall = mkBoolOpt false "Open firewall for GoatCounter";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services.postgresql = {
      ensureDatabases = [ "goatcounter" ];
      ensureUsers = [
        {
          name = "goatcounter";
          ensureDBOwnership = true;
        }
      ];
    };

    services.goatcounter = enabled // {
      inherit (cfg) port;
      proxy = true;
      extraArgs = [
        "-db"
        "postgresql+host=/run/postgresql dbname=goatcounter sslmode=disable"
        "-automigrate"
      ];
    };

    systemd.services.goatcounter = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };

    dots.services.caddy.services.stats = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
      auth = false;
    };
  };
}
