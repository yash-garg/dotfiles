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

  mkRouter = name: {
    inherit name;
    value = {
      rule = "Host(`${name}.${cfg.domain}`)";
      entryPoints = [ "websecure" ];
      service = name;
      tls.certResolver = "letsencrypt";
      middlewares =
        (cfg.services.${name}.middlewares or [ ]) ++ optional (cfg.services.${name}.useAuth or true) "auth";
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

    services = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            url = mkOpt types.str "https://${name}.${cfg.domain}" "URL of the service";
            useAuth = mkBoolOpt true "Whether to use authentication middleware";
            useInsecure = mkBoolOpt false "Whether to use insecure transport";
            middlewares = mkOpt (types.listOf types.str) [ ] "Additional middlewares to apply";
          };
        }
      );
      default = { };
      description = "Service configurations";
    };
  };

  config = mkIf cfg.enable {
    services.traefik = enabled // {
      inherit (cfg) environmentFiles;

      staticConfigOptions = {
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
          minecraft.address = ":25565";
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

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          level = "WARN";
          format = "json";
        };
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
                middlewares = [ "auth" ];
              };
            }
          ]
        );

        services = builtins.listToAttrs (
          map (name: mkService (cfg.services.${name} // { inherit name; })) (builtins.attrNames cfg.services)
        );

        middlewares = {
          auth.forwardAuth = {
            address = "http://localhost:9091/api/authz/forward-auth";
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

        serversTransports.insecure = {
          insecureSkipVerify = true;
        };
      };
    };
  };
}
