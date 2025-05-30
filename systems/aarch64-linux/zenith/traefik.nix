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
  oracle-ip = "100.78.157.31";

  mkRouter = name: auth: {
    inherit name;
    value = {
      rule = "Host(`${name}.${domain}`)";
      entryPoints = [ "websecure" ];
      service = name;
      tls.certResolver = "letsencrypt";
      middlewares = if auth then [ "auth" ] else [ ];
    };
  };

  mkService =
    {
      name,
      url,
      useInsecure ? false,
    }:
    {
      inherit name;
      value = {
        loadBalancer = {
          servers = [ { inherit url; } ];
          serversTransport = if useInsecure then "insecure" else null;
        };
      };
    };

  services = {
    budget = {
      url = "https://${oracle-ip}:5006";
      useInsecure = true;
    };

    cadvisor.url = "http://${oracle-ip}:8081";

    dns.url = "http://100.93.246.1";

    home.url = "http://100.65.53.36:8123";

    image.url = "http://${oracle-ip}:3474";

    map.url = "http://100.92.154.106:81";

    photos = {
      url = "http://${oracle-ip}:8086";
      auth = false;
    };

    prometheus.url = "http://${oracle-ip}:9090";

    prowlarr.url = "http://${oracle-ip}:9696";

    qbit.url = "http://${oracle-ip}:8080";

    read.url = "http://${oracle-ip}:5000";

    readarr.url = "http://${oracle-ip}:8787";

    radarr.url = "http://${oracle-ip}:7878";

    rss.url = "http://${oracle-ip}:5600";

    sonarr.url = "http://${oracle-ip}:8989";

    stats.url = "http://${oracle-ip}:3000";

    stream.url = "http://${oracle-ip}:8096";

    unraid = {
      url = "https://${oracle-ip}";
      useInsecure = true;
    };
  };

  routers = builtins.listToAttrs (
    map (name: mkRouter name (services.${name}.auth or true)) (builtins.attrNames services)
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
