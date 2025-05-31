{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  domain = "ipx.ovh";
  nova = "100.78.157.31";

  mkRouter = name: {
    inherit name;
    value = {
      rule = "Host(`${name}.${domain}`)";
      entryPoints = [ "websecure" ];
      service = name;
      tls.certResolver = "letsencrypt";
      middlewares = mkIf (services.${name}.useAuth or true) [ "auth" ];
    };
  };

  mkService =
    {
      name,
      url,
      useInsecure ? false,
      useAuth ? true,
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

  services = {
    budget = {
      url = "https://${nova}:5006";
      useInsecure = true;
    };

    cadvisor.url = "http://${nova}:8081";

    dns.url = "http://100.93.246.1";

    home.url = "http://100.65.53.36:8123";

    image.url = "http://${nova}:3474";

    map.url = "http://100.92.154.106:81";

    photos = {
      url = "http://${nova}:8086";
      useAuth = false;
    };

    prometheus.url = "http://${nova}:9090";

    prowlarr.url = "http://${nova}:9696";

    qbit.url = "http://${nova}:8080";

    read.url = "http://${nova}:5000";

    readarr.url = "http://${nova}:8787";

    radarr.url = "http://${nova}:7878";

    rss.url = "http://${nova}:5600";

    sonarr.url = "http://${nova}:8989";

    stats.url = "http://${nova}:3000";

    stream.url = "http://${nova}:8096";

    unraid = {
      url = "https://${nova}";
      useInsecure = true;
    };
  };

  routers = builtins.listToAttrs (
    map (name: mkRouter name) (builtins.attrNames services)
    ++ [
      {
        name = "traefik";
        value = {
          rule = "Host(`traefik.${domain}`)";
          entryPoints = [ "websecure" ];
          service = "api@internal";
          tls.certResolver = "letsencrypt";
          middlewares = [ "auth" ];
        };
      }
    ]
  );

  serviceConfigs = builtins.listToAttrs (
    map (name: mkService (services.${name} // { inherit name; })) (builtins.attrNames services)
  );
in
{
  age.secrets.cf-tokens = {
    file = getSecret "cf.env" "zenith";
    owner = config.services.traefik.group;
  };

  services.traefik = enabled // {
    environmentFiles = [ config.age.secrets.cf-tokens.path ];

    staticConfigOptions = {
      api = {
        dashboard = true;
        insecure = false;
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "spam@${domain}";
        storage = "/var/lib/traefik/acme.json";
        caServer = "https://acme-v02.api.letsencrypt.org/directory";
        dnsChallenge = {
          provider = "cloudflare";
          delayBeforeCheck = 0;
        };
      };

      entryPoints = {
        web.address = ":80";
        websecure.address = ":443";
      };

      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      log = {
        level = "INFO";
        format = "json";
      };
    };

    dynamicConfigOptions.http = {
      inherit routers;
      services = serviceConfigs;

      middlewares.auth.forwardAuth = {
        address = "http://localhost:9091/api/authz/forward-auth";
        trustForwardHeader = true;
        authResponseHeaders = [
          "Remote-User"
          "Remote-Groups"
          "Remote-Email"
          "Remote-Name"
        ];
      };

      serversTransports.insecure = {
        insecureSkipVerify = true;
      };
    };
  };
}
