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
    server = enabled;

    hardware.networking = enabled // {
      hostName = "zenith";
      ports = [
        80
        443
      ];
    };

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

        caddy = enabled // {
          domain = homeDomain;
          auth = enabled;
          services = {
            home = {
              domain = homeDomain;
              upstream = "http://homeassistant.${config.${namespace}.services.tailscale.tailnet}:8123";
            };
            unraid = {
              domain = homeDomain;
              upstream = "https://${nova}";
            };
          };
        };

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
                name = "ares";
                ip = "100.105.194.6";
                prometheus = true;
                loki = true;
              }
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
          acceptRoutes = true;
          ssh = true;
        };

        umami = enabled // {
          appSecretFile = config.sops.secrets.plausible-secret.path;
          baseUrl = domain;
        };
      };

    virtualisation = enabled;
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "bgptools-export";
      scheme = "https";
      metrics_path = "/prom/76dd5676-5af1-4e32-8716-381770873249";
      scrape_interval = "30s";
      static_configs = [
        { targets = [ "prometheus.bgp.tools" ]; }
      ];
    }
  ];

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
