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
  cfg = config.${namespace}.services.monitoring;
in
{
  options.${namespace}.services.monitoring = {
    enable = mkEnableOption "Monitoring and Alerting System";
    domain = mkOpt types.str "ipx.ovh" "Domain name for monitoring";
    alloy = {
      enable = mkEnableOption "Enable alloy";
      port = mkOpt types.int ports.alloy "Port for the alloy server";
    };
    grafana = {
      enable = mkEnableOption "Enable grafana";
      port = mkOpt types.int ports.grafana "Port for the grafana server";
    };
    loki = {
      enable = mkEnableOption "Enable loki";
      port = mkOpt types.int ports.loki "Port for the loki server";
    };
    prometheus = {
      enable = mkEnableOption "Enable prometheus";
      port = mkOpt types.int ports.prometheus "Port for the prometheus server";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = mkMerge [
      {
        alertmanager-ntfy = {
          sopsFile = lib.snowfall.fs.get-file "secrets/alertmanager.yaml";
          key = "ntfy-settings";
        };
      }
      (mkIf cfg.grafana.enable {
        grafana-env = {
          sopsFile = lib.snowfall.fs.get-file "secrets/grafana.env";
          format = "dotenv";
        };
      })
    ];

    services = {
      alloy = mkIf cfg.alloy.enable {
        inherit (cfg.alloy) enable;
        extraFlags = [
          "--server.http.listen-addr=0.0.0.0:${toString cfg.alloy.port}"
          "--disable-reporting"
        ];
      };

      grafana = mkIf cfg.grafana.enable {
        inherit (cfg.grafana) enable;
        provision = enabled // {
          dashboards.settings.providers = [
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
              name = "Miniflux";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "miniflux-grafana-dashboard.json";
                url = "https://raw.githubusercontent.com/miniflux/v2/e8f5c2446c9acfb89f0bf67176ce4c32e3ca9618/contrib/grafana/dashboard.json";
                hash = "sha256-U7Hp3eXXEnfPvJMhUkQkvtUrZw0nG3oa4bQ+gRcVmoE=";
              };
            }
            {
              name = "Minecraft (Fabric)";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "minecraft-fabric-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/14492/revisions/4/download";
                hash = "sha256-vdJGG9BZaTawR5b88qgWcjVI/LlrEycPiKrqeQB/V30=";
              };
            }
            {
              name = "NVIDIA GPU Metrics";
              allowUiUpdates = true;
              options.path = pkgs.fetchurl {
                name = "nvidia-gpu-metrics-1-grafana-dashboard.json";
                url = "https://grafana.com/api/dashboards/14574/revisions/11/download";
                hash = "sha256-0qQ+nVYZ9skOsGhpIFbTtxSkYxe7yRv6WF/56/lbgpw=";
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
              {
                name = "Prometheus (nova)";
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
              (mkIf cfg.loki.enable {
                name = "Loki (${config.networking.hostName})";
                type = "loki";
                access = "proxy";
                url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
              })
              {
                name = "Prometheus (quasar)";
                type = "prometheus";
                access = "proxy";
                url = "http://100.93.8.41:${toString config.services.prometheus.port}";
              }
              {
                name = "Loki (quasar)";
                type = "loki";
                access = "proxy";
                url = "http://100.93.8.41:${toString config.services.loki.configuration.server.http_listen_port}";
              }
              {
                name = "Prometheus (vortex)";
                type = "prometheus";
                access = "proxy";
                url = "http://100.65.244.114:${toString config.services.prometheus.port}";
              }
              {
                name = "Loki (vortex)";
                type = "loki";
                access = "proxy";
                url = "http://100.65.244.114:${toString config.services.loki.configuration.server.http_listen_port}";
              }
            ];
          };
        };
        settings =
          let
            ssoEnabled = config.${namespace}.services.sso.enable;
          in
          {
            auth.disable_login_form = ssoEnabled;
            "auth.generic_oauth" = {
              enabled = ssoEnabled;
              name = "Authelia";
              icon = "signin";
              scopes = "openid,email,profile,groups";
              empty_scopes = false;
              auth_url = "https://auth.${cfg.domain}/api/oidc/authorization";
              token_url = "https://auth.${cfg.domain}/api/oidc/token";
              api_url = "https://auth.${cfg.domain}/api/oidc/userinfo";
              login_attribute_path = "preferred_username";
              groups_attribute_path = "groups";
              name_attribute_path = "name";
              use_pkce = true;
              auto_login = false;
              role_attribute_path = "contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'";
            };
            analytics.feedback_links_enabled = false;
            server = {
              inherit (cfg) domain;
              root_url = "https://grafana.${cfg.domain}";
              http_addr = "127.0.0.1";
              http_port = cfg.grafana.port;
            };
          };
      };

      loki = mkIf cfg.loki.enable {
        inherit (cfg.loki) enable;
        configuration =
          let
            inherit (config.services.loki) dataDir;
          in
          {
            analytics.reporting_enabled = false;
            auth_enabled = false;
            server = {
              http_listen_port = cfg.loki.port;
              grpc_listen_port = 0;
              log_level = "warn";
            };
            common = {
              replication_factor = 1;
              path_prefix = dataDir;
              ring = {
                instance_addr = "127.0.0.1";
                kvstore.store = "inmemory";
              };
            };
            ingester = {
              lifecycler = {
                address = "127.0.0.1";
                ring = {
                  kvstore.store = "inmemory";
                  replication_factor = 1;
                };
                final_sleep = "0s";
              };
              chunk_idle_period = "5m";
              chunk_retain_period = "30s";
            };
            limits_config = {
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
            };
            query_scheduler.max_outstanding_requests_per_tenant = 2048;
            ruler.alertmanager_url = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
            storage_config.filesystem.directory = "${dataDir}/chunks";
            schema_config = {
              configs = [
                {
                  from = "2024-04-01";
                  store = "tsdb";
                  object_store = "filesystem";
                  schema = "v13";
                  index = {
                    prefix = "index_";
                    period = "24h";
                  };
                }
              ];
            };
          };
      };

      prometheus = enabled // {
        inherit (cfg.prometheus) enable port;
        extraFlags = [ "--web.enable-admin-api" ];
        alertmanager = enabled // {
          port = ports.alertmanager;
          configuration = {
            route.receiver = "ntfy";
            receivers = [
              {
                name = "ntfy";
                webhook_configs = [
                  { url = "http://127.0.0.1:${toString ports.alertmanager-ntfy}/hook"; }
                ];
              }
            ];
          };
        };
        alertmanagers = [
          {
            scheme = "http";
            static_configs = [
              { targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ]; }
            ];
          }
        ];
        alertmanager-ntfy = enabled // {
          extraConfigFiles = [ config.sops.secrets.alertmanager-ntfy.path ];
          settings = {
            http.addr = "127.0.0.1:${toString ports.alertmanager-ntfy}";
            ntfy = {
              baseurl = "https://ntfy.sh";
              notification.topic = "";
            };
          };
        };
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
                targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ];
                labels.alias = "alertmanager";
              }
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
          rule = "Host(`grafana.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "grafana";
          tls.certResolver = "letsencrypt";
        };

        services.grafana.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.grafana.port}"; } ];
        };
      };
    };

    environment.etc."alloy/config.alloy" = mkIf cfg.alloy.enable {
      source = ./config.alloy;
    };

    systemd.services.alloy = mkIf cfg.alloy.enable {
      serviceConfig = {
        User = "root";
        Group = "root";
        DynamicUser = mkForce false;
      };
    };

    systemd.services.grafana.serviceConfig = mkIf cfg.grafana.enable {
      EnvironmentFile = [ config.sops.secrets.grafana-env.path ];
    };
  };
}
