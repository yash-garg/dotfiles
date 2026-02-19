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
  cfg = config.${namespace}.services.caddy;

  cloudflareIPs = [
    # IPv4
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    # IPv6
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];

  localIPs = [
    "127.0.0.1/32"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
  ];

  trustedProxies = localIPs ++ cloudflareIPs;

  # Generate "sub1.domain sub2.domain ..." from list
  mkHosts = svcs: concatMapStringsSep " " (s: "${s}.${cfg.domain}") svcs;

  # Generate reverse_proxy block for a server
  mkProxy =
    name: srv:
    let
      upstreams = if srv.fallback != null then "${srv.primary} ${srv.fallback}" else srv.primary;
      commonOpts = ''
        ${optionalString (srv.fallback != null) "lb_policy first"}
        header_up Host {host}
        header_up X-Real-IP {remote_host}
      '';
    in
    ''
      @${name} host ${mkHosts srv.services}
      handle @${name} {
        @ws {
          header Connection *Upgrade*
          header Upgrade websocket
        }
        reverse_proxy @ws ${upstreams} {
          ${commonOpts}
          transport http {
            tls
            tls_server_name {host}
            versions 1.1
          }
        }
        reverse_proxy ${upstreams} {
          ${commonOpts}
          transport http {
            tls
            tls_server_name {host}
            versions 2
          }
        }
      }
    '';
in
{
  options.${namespace}.services.caddy = {
    enable = mkEnableOption "Setup caddy reverse proxy";
    domain = mkOpt types.str "ipx.ovh" "Base domain for all services";
    environmentFile =
      mkOpt (types.nullOr types.str) null
        "Environment file for secrets (e.g., CF_API_TOKEN)";

    servers = mkOpt (types.attrsOf (
      types.submodule {
        options = {
          primary = mkOpt types.str "" "Primary upstream address (e.g., [ipv6]:443)";
          fallback = mkOpt (types.nullOr types.str) null "Fallback upstream address";
          services = mkOpt (types.listOf types.str) [ ] "List of subdomains to route to this server";
        };
      }
    )) { } "Server configurations with upstreams and services";
  };

  config = mkIf cfg.enable {
    services = {
      caddy = enabled // {
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
          hash = "sha256-bJO2RIa6hYsoVl3y2L86EM34Dfkm2tlcEsXn2+COgzo";
        };
        inherit (cfg) environmentFile;
        globalConfig = ''
          acme_dns cloudflare {env.CF_DNS_API_TOKEN}
          metrics
          servers {
            trusted_proxies static ${concatStringsSep " " trustedProxies}
          }
        '';
        logFormat = ''
          output file /var/log/caddy/caddy_main.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 100d
          }
          format json
          level INFO
        '';
        extraConfig = mkIf (cfg.servers != { }) ''
          *.${cfg.domain} {
            ${concatStrings (mapAttrsToList mkProxy cfg.servers)}
            handle {
              respond "Public Ingress Proxy. Nothing to see." 404
            }
          }
        '';
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "caddy";
          static_configs = [ { targets = [ "localhost:${toString ports.exporters.caddy}" ]; } ];
        }
      ];
    };
  };
}
