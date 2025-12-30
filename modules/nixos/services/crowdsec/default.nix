{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.crowdsec;
in
{
  options.${namespace}.services.crowdsec = {
    enable = mkEnableOption "CrowdSec: Intrusion Prevention System";
    user = mkOpt types.str "crowdsec" "User to run the service as";
    group = mkOpt types.str "crowdsec" "Group to run the service as";
    port = mkOpt types.int ports.crowdsec "Port to listen on";
  };

  config = mkIf cfg.enable {
    services = {
      crowdsec = enabled // {
        inherit (cfg) user group;
        autoUpdateService = true;
        openFirewall = true;
        hub = {
          collections = [
            "crowdsecurity/linux"
            "crowdsecurity/traefik"
            "crowdsecurity/http-cve"
            "crowdsecurity/whitelist-good-actors"
            "LePresidente/authelia"
          ];
          postOverflows = [ "crowdsecurity/cdn-whitelist" ];
          scenarios = [
            "crowdsecurity/ssh-bf"
            "crowdsecurity/ssh-slow-bf"
            "crowdsecurity/http-crawl-non_statics"
            "crowdsecurity/http-probing"
            "crowdsecurity/http-sensitive-files"
            "crowdsecurity/http-bad-user-agent"
          ];
        };
        localConfig = {
          acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [
                "_SYSTEMD_UNIT=traefik.service"
              ];
              labels.type = "traefik";
            }
            {
              source = "journalctl";
              journalctl_filter = [
                "_SYSTEMD_UNIT=authelia-main.service"
              ];
              labels.type = "authelia";
            }
          ];
          contexts = [
            {
              context = {
                target_host = [ "evt.Meta.http_host" ];
                target_uri = [ "evt.Meta.http_path" ];
                http_method = [ "evt.Meta.http_verb" ];
                http_status = [ "evt.Meta.http_status" ];
                user_agent = [ "evt.Meta.http_user_agent" ];
              };
            }
          ];
        };
        settings = {
          lapi.credentialsFile = "/var/lib/crowdsec/state/lapi.yaml";
          general = {
            api.server = enabled // {
              listen_uri = "127.0.0.1:${toString cfg.port}";
            };
            db_config = {
              type = "postgres";
              user = "crowdsec";
              password = "crowdsec";
              db_name = "crowdsec";
              host = "/run/postgresql";
              port = ports.postgres;
            };
            prometheus.listen_port = ports.exporters.crowdsec;
          };
        };
      };

      postgresql = {
        ensureDatabases = [ "crowdsec" ];
        ensureUsers = [
          {
            name = "crowdsec";
            ensureDBOwnership = true;
          }
        ];
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "crowdsec";
          static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.crowdsec}" ]; } ];
        }
      ];
    };
  };
}
