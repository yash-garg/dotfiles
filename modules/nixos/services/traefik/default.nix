{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.traefik;

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

  trustedIPs = localIPs ++ cloudflareIPs;

  mkRouter =
    name:
    let
      svc = cfg.services.${name};
      middlewares = (optional (svc.useAuth or true) "auth") ++ (svc.middlewares or [ ]);
    in
    {
      inherit name;
      value = {
        rule = "Host(`${name}.${cfg.domain}`)";
        entryPoints = [ "websecure" ];
        service = name;
        tls.certResolver = "letsencrypt";
        inherit middlewares;
      };
    };

  mkService =
    {
      name,
      url,
      useInsecure ? false,
      useAuth ? true,
      middlewares ? [ ],
    }:
    {
      inherit name;
      value = {
        loadBalancer = {
          servers = [ { inherit url; } ];
          serversTransport = mkIf useInsecure "insecure";
        };
      };
    };
in
{
  options.${namespace}.services.traefik = {
    enable = mkEnableOption "Setup traefik reverse proxy";
    domain = mkOpt types.str "ipx.ovh" "Base domain for all services";
    environmentFiles = mkOpt (types.listOf types.str) [ ] "Environment files to load";
    services = mkOpt (types.attrsOf (
      types.submodule {
        options = {
          url = mkOpt types.str "https://${name}.${cfg.domain}" "URL of the service";
          useAuth = mkBoolOpt true "Whether to use authentication middleware";
          useInsecure = mkBoolOpt false "Whether to use insecure transport";
          middlewares = mkOpt (types.listOf types.str) [ ] "Additional middlewares to apply";
        };
      }
    )) { } "Service configurations";
  };

  config = mkIf cfg.enable {
    services.traefik = enabled // {
      inherit (cfg) environmentFiles;
      useEnvSubst = false;

      static.settings = {
        accessLog.format = "json";

        api = {
          dashboard = true;
          insecure = false;
        };

        certificatesResolvers.letsencrypt.acme = {
          email = "spam@${cfg.domain}";
          storage = "${config.services.traefik.dataDir}/acme.json";
          caServer = "https://acme-v02.api.letsencrypt.org/directory";
          dnsChallenge = {
            provider = "cloudflare";
            delayBeforeCheck = 0;
          };
        };

        entryPoints = {
          web = {
            address = ":80";
            forwardedHeaders.trustedIPs = trustedIPs;
            transport.respondingTimeouts = {
              readTimeout = 600;
              writeTimeout = 600;
              idleTimeout = 600;
            };
          };
          websecure = {
            address = ":443";
            forwardedHeaders.trustedIPs = trustedIPs;
            transport.respondingTimeouts = {
              readTimeout = 600;
              writeTimeout = 600;
              idleTimeout = 600;
            };
          };
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          level = "DEBUG";
          format = "json";
        };

        metrics.prometheus = {
          addEntryPointsLabels = true;
          addRoutersLabels = true;
          addServicesLabels = true;
        };

        ping.entryPoint = "traefik";
      };

      dynamic.dir = "/var/lib/traefik/dynamic";
      dynamic.files.main.settings.http = {
        routers = builtins.listToAttrs (
          map mkRouter (builtins.attrNames cfg.services)
          ++ [
            {
              name = "traefik";
              value = {
                rule = "Host(`traefik.${cfg.domain}`)";
                entryPoints = [ "websecure" ];
                service = "api@internal";
                tls.certResolver = "letsencrypt";
                middlewares = [
                  "auth"
                ];
              };
            }
          ]
        );

        services = builtins.listToAttrs (
          map (name: mkService (cfg.services.${name} // { inherit name; })) (builtins.attrNames cfg.services)
        );

        middlewares = {
          auth.forwardAuth = {
            address = "http://localhost:${toString ports.authelia}/api/authz/forward-auth";
            trustForwardHeader = true;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ];
          };

          jellyfin-redirect.redirectRegex = {
            permanent = true;
            regex = "^https://stream.${cfg.domain}/?$";
            replacement = "https://stream.${cfg.domain}/sso/OID/start/authelia";
          };
        };

        serversTransports.insecure.insecureSkipVerify = true;
      };
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "traefik";
        static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
      }
    ];
  };
}
