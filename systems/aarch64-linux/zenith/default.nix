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
  domain = "yashgarg.dev";
  homeDomain = "ipx.ovh";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    cf-tokens = {
      sopsFile = snowfall.fs.get-file "secrets/cloudflare.env";
      format = "dotenv";
      owner = config.services.traefik.group;
    };
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = config.networking.hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
    plausible-secret.sopsFile = snowfall.fs.get-file "secrets/plausible.yaml";
  };

  boot = {
    loader = {
      systemd-boot = enabled;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd.systemd = enabled;
  };

  dots = {
    hardware.networking = enabled // {
      hostName = "zenith";
      domain = "";
      tcpPorts = [
        80
        443
      ];
    };

    server = enabled;

    services =
      let
        inherit (config.${namespace}.services.tailscale) tailnet;
        nova = "nova.${tailnet}";
        quasar = "quasar.${tailnet}";
        vortex = "vortex.${tailnet}";
      in
      {
        actual-budget = enabled // {
          backup = enabled;
          domain = homeDomain;
        };

        atticd = enabled // {
          bucket = "attic-cache";
          endpoint = "https://a69e81e6342baaeed47710799b04477a.r2.cloudflarestorage.com";
        };

        crowdsec = enabled;

        forgejo = enabled // {
          domain = homeDomain;
        };

        gatus = enabled // {
          inherit domain;
          endpoints = {
            actual-budget = {
              name = "Actual Budget";
              url = "http://localhost:${toString ports.actual-budget}";
            };
            atticd = {
              name = "Attic Cache";
              url = "https://cache.${homeDomain}";
            };
            authelia = {
              name = "Authelia";
              url = "http://localhost:${toString ports.authelia}";
            };
            bazarr = {
              name = "Bazarr";
              url = "http://${quasar}:${toString ports.bazarr}";
            };
            bentopdf = {
              name = "BentoPDF";
              url = "http://${quasar}:${toString ports.bentopdf}";
            };
            calibre-web = {
              name = "Calibre Web";
              url = "http://${quasar}:${toString ports.calibre}";
            };
            copyparty = {
              name = "Copyparty";
              url = "http://${quasar}:${toString ports.copyparty}";
            };
            crowdsec = {
              name = "CrowdSec";
              url = "http://localhost:${toString ports.crowdsec}/v1/heartbeat";
              extraConditions = [ "[STATUS] == 401" ];
            };
            forgejo = {
              name = "Forgejo";
              url = "http://localhost:${toString ports.forgejo}";
            };
            grafana = {
              name = "Grafana";
              url = "http://localhost:9092";
            };
            home-assistant = {
              name = "Home Assistant";
              url = "http://homeassistant.${tailnet}:8123";
            };
            immich = {
              name = "Immich";
              url = "http://${quasar}:${toString ports.immich.webui}";
            };
            jellyfin = {
              name = "Jellyfin";
              url = "http://${quasar}:${toString ports.jellyfin}";
            };
            jellyseerr = {
              name = "Jellyseerr";
              url = "http://${quasar}:${toString ports.jellyseerr}";
            };
            linkding = {
              name = "Linkding";
              url = "http://localhost:${toString ports.linkding}";
            };
            lldap = {
              name = "LLDAP";
              url = "http://localhost:${toString ports.lldap}";
            };
            mealie = {
              name = "Mealie";
              url = "http://${quasar}:${toString ports.mealie}";
            };
            miniflux = {
              name = "Miniflux";
              url = "http://${quasar}:${toString ports.miniflux}";
            };
            minecraft-server = {
              name = "Minecraft Server";
              url = "udp://${vortex}:${toString ports.minecraft}";
            };
            minecraft-map = {
              name = "Minecraft Map";
              url = "http://${vortex}:${toString ports.pl3xmap}";
            };
            paperless = {
              name = "Paperless NGX";
              url = "http://${quasar}:${toString ports.paperless-ngx}";
            };
            postgres-primary = {
              name = "PostgreSQL Primary";
              url = "tcp://localhost:${toString ports.postgres}";
            };
            postgres-secondary = {
              name = "PostgreSQL Secondary";
              url = "tcp://${quasar}:${toString ports.postgres}";
            };
            prometheus = {
              name = "Prometheus";
              url = "http://${quasar}:${toString ports.prometheus}";
            };
            prowlarr = {
              name = "Prowlarr";
              url = "http://${quasar}:${toString ports.prowlarr}";
            };
            qbittorrent = {
              name = "qBittorrent";
              url = "http://${quasar}:${toString ports.qbittorrent.webui}";
            };
            radarr = {
              name = "Radarr";
              url = "http://${quasar}:${toString ports.radarr}";
            };
            sonarr = {
              name = "Sonarr";
              url = "http://${quasar}:${toString ports.sonarr}";
            };
            traefik = {
              name = "Traefik";
              url = "http://localhost:8080/ping";
            };
            umami = {
              name = "Umami";
              url = "http://localhost:${toString ports.umami}";
            };
            unraid = {
              name = "Unraid";
              url = "http://${nova}";
            };
          };
        };

        linkding = enabled // {
          database = enabled;
          proxy = enabled // {
            domain = homeDomain;
          };
        };

        monitoring = enabled // {
          domain = homeDomain;
          alloy = enabled;
          grafana = enabled // {
            remoteDatasources = [
              {
                name = "quasar";
                ip = "100.93.8.41";
                prometheus = true;
                loki = true;
              }
              {
                name = "vortex";
                ip = "100.65.244.114";
                prometheus = true;
                loki = true;
              }
            ];
          };
          loki = enabled;
          prometheus = enabled;
        };

        postgres = enabled // {
          backup = enabled;
        };

        restic = enabled;

        ssh = enabled // {
          addRootKeys = true;
          passwordAuth = false;
          permitRootLogin = false;
        };

        sso = enabled // {
          domain = homeDomain;
        };

        tailscale = enabled // {
          authKeyFile = config.sops.secrets.server-tsauthkey.path;
          exitNode = true;
          ssh = true;
          subnetRouting = enabled // {
            routes = [
              "192.168.0.0/24"
              "192.168.1.0/24"
            ];
          };
        };

        traefik = enabled // {
          domain = homeDomain;
          environmentFiles = [ config.sops.secrets.cf-tokens.path ];
          services = {
            bazarr.url = "http://$ARR_USER:$ARR_PASSWORD@${quasar}:${toString ports.bazarr}";
            books.url = "http://${quasar}:${toString ports.calibre}";
            fs = {
              url = "http://${quasar}:${toString ports.copyparty}";
              useInsecure = true;
            };
            home.url = "http://homeassistant.${tailnet}:8123";
            map.url = "http://${vortex}:81";
            meals = {
              url = "http://${quasar}:${toString ports.mealie}";
              useAuth = false;
            };
            paperless.url = "http://${quasar}:${toString ports.paperless-ngx}";
            pdf = {
              url = "http://${quasar}:${toString ports.bentopdf}";
              useAuth = false;
            };
            photos = {
              url = "http://${quasar}:${toString ports.immich.webui}";
              useAuth = false;
            };
            prometheus.url = "http://${quasar}:${toString ports.prometheus}";
            prowlarr.url = "http://$ARR_USER:$ARR_PASSWORD@${quasar}:${toString ports.prowlarr}";
            qbit.url = "http://${quasar}:${toString ports.qbittorrent.webui}";
            radarr.url = "http://$ARR_USER:$ARR_PASSWORD@${quasar}:${toString ports.radarr}";
            requests.url = "http://${quasar}:${toString ports.jellyseerr}";
            rss.url = "http://${quasar}:${toString ports.miniflux}";
            sonarr.url = "http://$ARR_USER:$ARR_PASSWORD@${quasar}:${toString ports.sonarr}";
            stream = {
              url = "http://${quasar}:${toString ports.jellyfin}";
              useAuth = false;
              middlewares = [
                "crowdsec"
                "jellyfin-redirect"
              ];
            };
            unraid = {
              url = "https://${nova}";
              useInsecure = true;
            };
          };
        };

        umami = enabled // {
          appSecretFile = config.sops.secrets.plausible-secret.path;
          baseUrl = domain;
        };
      };
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" ];
  };

  # Enable passwordless sudo.
  security.sudo.extraRules = [
    {
      users = [ "yash" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "26.05";
}
