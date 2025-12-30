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

  mkRouter =
    name:
    let
      svc = cfg.services.${name};
      middlewares = [ "crowdsec" ] ++ (optional (svc.useAuth or true) "auth") ++ (svc.middlewares or [ ]);
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
    sops.secrets.crowdsec-api-key = {
      sopsFile = snowfall.fs.get-file "secrets/traefik.yaml";
      key = "crowdsec_api_key";
      owner = "traefik";
      group = "traefik";
      mode = "0400";
      restartUnits = [ "traefik.service" ];
    };

    services.traefik = enabled // {
      inherit (cfg) environmentFiles;

      staticConfigOptions = {
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
            transport.respondingTimeouts = {
              readTimeout = 600;
              writeTimeout = 600;
              idleTimeout = 600;
            };
          };
          websecure = {
            address = ":443";
            transport.respondingTimeouts = {
              readTimeout = 600;
              writeTimeout = 600;
              idleTimeout = 600;
            };
          };
        };

        experimental.plugins.bouncer = {
          moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
          version = "v1.5.0-beta1";
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

      dynamicConfigOptions.http = {
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
                  "crowdsec"
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

          crowdsec.plugin.bouncer = {
            enabled = true;
            logLevel = "INFO";
            crowdsecMode = "stream";
            crowdsecLapiScheme = "http";
            crowdsecLapiHost = "127.0.0.1:${toString ports.crowdsec}";
            crowdsecLapiKeyFile = config.sops.secrets.crowdsec-api-key.path;
            forwardedHeadersTrustedIPs = [
              "127.0.0.1/32"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
            clientTrustedIPs = [
              "127.0.0.1/32"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
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
