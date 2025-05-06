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
      routers = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = {
              rule = "Host(`" + name + ".${domain}`)";
              entryPoints = [ "websecure" ];
              service = name;
              tls.certResolver = "letsencrypt";
              middlewares = [ "auth" ];
            };
          })
          [
            "budget"
            "cadvisor"
            "cam"
            "image"
            "map"
            "prometheus"
            "prowlarr"
            "qbit"
            "radarr"
            "rss"
            "sonarr"
            "stats"
            "stream"
            "unraid"
          ]
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

      services = {
        budget.loadBalancer = {
          servers = [ { url = "https://100.78.157.31:5006"; } ];
          serversTransport = "insecure";
        };
        cadvisor.loadBalancer.servers = [ { url = "http://100.78.157.31:8081"; } ];
        cam.loadBalancer.servers = [ { url = "http://100.78.157.31:1984"; } ];
        image.loadBalancer.servers = [ { url = "http://100.78.157.31:3474"; } ];
        map.loadBalancer.servers = [ { url = "http://100.92.154.106:81"; } ];
        prometheus.loadBalancer.servers = [ { url = "http://100.78.157.31:9090"; } ];
        prowlarr.loadBalancer.servers = [ { url = "http://100.78.157.31:9696"; } ];
        qbit.loadBalancer.servers = [ { url = "http://100.78.157.31:8080"; } ];
        radarr.loadBalancer.servers = [ { url = "http://100.78.157.31:7878"; } ];
        rss.loadBalancer.servers = [ { url = "http://100.78.157.31:5600"; } ];
        sonarr.loadBalancer.servers = [ { url = "http://100.78.157.31:8989"; } ];
        stats.loadBalancer.servers = [ { url = "http://100.78.157.31:3000"; } ];
        stream.loadBalancer.servers = [ { url = "http://100.78.157.31:8096"; } ];
        unraid.loadBalancer = {
          servers = [ { url = "https://100.78.157.31"; } ];
          serversTransport = "insecure";
        };
      };
    };
  };
}
