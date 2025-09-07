{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.prometheus;
in
{
  options.${namespace}.services.prometheus = {
    enable = mkEnableOption "Prometheus: Monitoring and Alerting System";
    grafana = {
      enable = mkEnableOption "Enable grafana";
      domain = mkOpt types.str "ipx.ovh" "Domain name for prometheus";
    };
    port = mkOpt types.int ports.prometheus "Port for the prometheus server";
  };

  config = mkIf cfg.enable {
    sops.secrets = mkMerge [
      (mkIf cfg.grafana.enable {
        grafana-env = {
          sopsFile = lib.snowfall.fs.get-file "secrets/grafana.env";
          format = "dotenv";
        };
      })
    ];

    services = {
      grafana = mkIf cfg.grafana.enable {
        inherit (cfg.grafana) enable;
        provision = enabled // {
          dashboards.settings.providers = [
            {
              name = "Cadvisor Exporter";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "cadvisor-exporter-1-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/14282/revisions/1/download";
                hash = "sha256-dqhaC4r4rXHCJpASt5y3EZXW00g5fhkQM+MgNcgX1c0=";
              };
            }
            {
              name = "Node Exporter Full";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "node-exporter-full-41-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
                hash = "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
              };
            }
            {
              name = "NVIDIA SMI Metrics";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "nvidia-smi-metrics-1-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/12357/revisions/1/download";
                hash = "sha256-zOnzgrhKVecZ2OJpOWKrPUoI6f6G6V9wRowu09svKLw=";
              };
            }
            {
              name = "PostgresSQL Database";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "postgres-database-8-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/9628/revisions/8/download";
                hash = "sha256-UhusNAZbyt7fJV/DhFUK4FKOmnTpG0R15YO2r+nDnMc=";
              };
            }
            {
              name = "Systemd Exporter";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "systemd-exporter-3-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/23844/revisions/3/download";
                hash = "sha256-/wpWvsZS4i8vkxQI/6qhsiwv1cDVWQBk31ZDFFxu8H4=";
              };
            }
          ];
          datasources.settings = {
            deleteDatasources = [
              {
                name = "Prometheus (Unraid)";
                orgId = 1;
              }
            ];

            datasources = [
              {
                name = "Prometheus (${config.networking.hostName})";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              }
              {
                name = "Prometheus (nova)";
                type = "prometheus";
                access = "proxy";
                url = "http://100.78.157.31:9090";
              }
              {
                name = "Prometheus (vortex)";
                type = "prometheus";
                access = "proxy";
                url = "http://100.65.244.114:${toString config.services.prometheus.port}";
              }
            ];
          };
        };
        settings = {
          auth.disable_login_form = true;
          "auth.generic_oauth" = {
            enabled = true;
            name = "Authelia";
            icon = "signin";
            scopes = "openid,email,profile,groups";
            empty_scopes = false;
            auth_url = "https://auth.${cfg.grafana.domain}/api/oidc/authorization";
            token_url = "https://auth.${cfg.grafana.domain}/api/oidc/token";
            api_url = "https://auth.${cfg.grafana.domain}/api/oidc/userinfo";
            login_attribute_path = "preferred_username";
            groups_attribute_path = "groups";
            name_attribute_path = "name";
            use_pkce = true;
            auto_login = false;
            role_attribute_path = "contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'";
          };
          analytics.feedback_links_enabled = false;
          server = {
            inherit (cfg.grafana) domain;
            root_url = "https://grafana.${cfg.grafana.domain}";
            http_addr = "127.0.0.1";
            http_port = ports.grafana;
          };
        };
      };

      prometheus = enabled // {
        inherit (cfg) port;
        extraFlags = [ "--web.enable-admin-api" ];
        exporters = {
          node = enabled // {
            enabledCollectors = [ "systemd" ];
            port = ports.exporters.node;
          };
          systemd = enabled // {
            port = ports.exporters.systemd;
          };
        };
        scrapeConfigs = [
          {
            job_name = config.networking.hostName;
            static_configs = [
              {
                targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
                labels.alias = "prometheus";
              }
              {
                targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
                labels.alias = "node-exporter";
              }
              {
                targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.systemd.port}" ];
                labels.alias = "systemd";
              }
            ];
          }
        ];
      };

      traefik.dynamicConfigOptions.http = mkIf cfg.grafana.enable {
        routers.grafana = {
          rule = "Host(`grafana.${cfg.grafana.domain}`)";
          entryPoints = [ "websecure" ];
          service = "grafana";
          tls.certResolver = "letsencrypt";
        };

        services.grafana.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.grafana}"; } ];
        };
      };
    };

    systemd.services.grafana.serviceConfig = mkIf cfg.grafana.enable {
      EnvironmentFile = [ config.sops.secrets.grafana-env.path ];
    };
  };
}
