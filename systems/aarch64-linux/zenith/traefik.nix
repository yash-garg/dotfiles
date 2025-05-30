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
            "dns"
            "home"
            "image"
            "map"
            "prometheus"
            "prowlarr"
            "qbit"
            "radarr"
            "readarr"
            "read"
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
          {
            name = "photos";
            value = {
              rule = "Host(`photos.${domain}`)";
              entryPoints = [ "websecure" ];
              service = "photos";
              tls.certResolver = "letsencrypt";
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

      services =
        let
          oracle-ip = "100.78.157.31";
        in
        {
          budget.loadBalancer = {
            servers = [ { url = "https://${oracle-ip}:5006"; } ];
            serversTransport = "insecure";
          };
          cadvisor.loadBalancer.servers = [ { url = "http://${oracle-ip}:8081"; } ];
          dns.loadBalancer.servers = [ { url = "http://100.93.246.1"; } ];
          home.loadBalancer.servers = [ { url = "http://100.65.53.36:8123"; } ];
          image.loadBalancer.servers = [ { url = "http://${oracle-ip}:3474"; } ];
          map.loadBalancer.servers = [ { url = "http://100.92.154.106:81"; } ];
          photos.loadBalancer.servers = [ { url = "http://${oracle-ip}:8086"; } ];
          prometheus.loadBalancer.servers = [ { url = "http://${oracle-ip}:9090"; } ];
          prowlarr.loadBalancer.servers = [ { url = "http://${oracle-ip}:9696"; } ];
          qbit.loadBalancer.servers = [ { url = "http://${oracle-ip}:8080"; } ];
          read.loadBalancer.servers = [ { url = "http://${oracle-ip}:5000"; } ];
          readarr.loadBalancer.servers = [ { url = "http://${oracle-ip}:8787"; } ];
          radarr.loadBalancer.servers = [ { url = "http://${oracle-ip}:7878"; } ];
          rss.loadBalancer.servers = [ { url = "http://${oracle-ip}:5600"; } ];
          sonarr.loadBalancer.servers = [ { url = "http://${oracle-ip}:8989"; } ];
          stats.loadBalancer.servers = [ { url = "http://${oracle-ip}:3000"; } ];
          stream.loadBalancer.servers = [ { url = "http://${oracle-ip}:8096"; } ];
          unraid.loadBalancer = {
            servers = [ { url = "https://${oracle-ip}"; } ];
            serversTransport = "insecure";
          };
        };
    };
  };
}
