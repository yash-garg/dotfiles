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
    "100.64.0.0/10"
  ];

  trustedProxies = localIPs ++ cloudflareIPs;

  mkHosts = svcs: concatMapStringsSep " " (s: "${s}.${cfg.domain}") svcs;

  mkServerProxy =
    name: srv:
    let
      upstreams = if srv.fallback != null then "${srv.address} ${srv.fallback}" else srv.address;
      usesTls = hasInfix ":443" srv.address || hasPrefix "https://" srv.address;
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
          ${optionalString usesTls ''
            transport http {
              tls
              tls_server_name {host}
              versions 1.1
            }
          ''}
        }
        reverse_proxy ${upstreams} {
          ${commonOpts}
          ${optionalString usesTls ''
            transport http {
              tls
              tls_server_name {host}
              versions 2
            }
          ''}
        }
      }
    '';

  forwardAuthSnippet =
    let
      authHost = if cfg.auth.url != "" then cfg.auth.url else "localhost:${toString cfg.auth.port}";
    in
    ''
      forward_auth ${authHost} {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
    '';

  mkServiceConfig =
    name: svc:
    let
      subdomain = if svc.subdomain != null then svc.subdomain else name;
      host = "${subdomain}.${svc.domain}";
      upstream =
        if hasPrefix "http://" svc.upstream || hasPrefix "https://" svc.upstream then
          svc.upstream
        else
          "http://${svc.upstream}";
    in
    ''
      ${host} {
        ${optionalString (cfg.auth.enable && svc.auth) forwardAuthSnippet}
        reverse_proxy ${upstream}
      }
    '';

  ingressConfig = optionalString (cfg.servers != { }) ''
    *.${cfg.domain} {
      ${concatStrings (mapAttrsToList mkServerProxy cfg.servers)}
      handle {
        respond "Not found" 404
      }
    }
  '';

  internalConfig = optionalString (cfg.services != { }) (
    concatStrings (mapAttrsToList mkServiceConfig cfg.services)
  );

  serviceSubmodule = types.submodule (_: {
    options = {
      subdomain = mkOpt (types.nullOr types.str) null "Subdomain (defaults to attribute name)";
      domain = mkOpt types.str cfg.domain "Domain for this service";
      upstream = mkOpt types.str "" "Upstream URL";
      auth = mkBoolOpt true "Use forward auth";
    };
  });

  serverSubmodule = types.submodule {
    options = {
      address = mkOpt types.str "" "Primary upstream address";
      fallback = mkOpt (types.nullOr types.str) null "Fallback upstream address";
      services = mkOpt (types.listOf types.str) [ ] "Subdomains to route";
    };
  };
in
{
  options.dots.services.caddy = {
    enable = mkEnableOption "Caddy reverse proxy";
    domain = mkOpt types.str "ipx.ovh" "Base domain";

    auth = {
      enable = mkBoolOpt false "Enable forward auth";
      port = mkOpt types.int ports.authelia "Authelia port";
      url = mkOpt types.str "" "Remote auth URL";
    };

    servers = mkOpt (types.attrsOf serverSubmodule) { } "Backend servers for ingress";
    services = mkOpt (types.attrsOf serviceSubmodule) { } "Local services";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      cf-env = {
        sopsFile = snowfall.fs.get-file "secrets/cloudflare.env";
        format = "dotenv";
        owner = config.services.caddy.user;
        inherit (config.services.caddy) group;
      };
      caddy-origin-cert = {
        sopsFile = snowfall.fs.get-file "secrets/cert.pem";
        format = "binary";
        owner = config.services.caddy.user;
        inherit (config.services.caddy) group;
      };
    };

    services = {
      caddy = enabled // {
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
          hash = "sha256-bJO2RIa6hYsoVl3y2L86EM34Dfkm2tlcEsXn2+COgzo";
        };
        environmentFile = config.sops.secrets.cf-env.path;
        globalConfig = ''
          acme_dns cloudflare {env.CF_DNS_API_TOKEN}
          email spam@${cfg.domain}
          metrics
          servers {
            trusted_proxies static ${concatStringsSep " " trustedProxies}
          }
        '';
        logFormat = "level INFO";
        extraConfig = ingressConfig + internalConfig;
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
