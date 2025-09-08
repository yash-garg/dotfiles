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
  hostName = "zenith";
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

  networking = {
    domain = "";
    hostName = "zenith";
    firewall.allowedTCPPorts = [
      80
      443
    ];
    networkmanager = enabled;
  };

  dots = {
    server = enabled;

    services = {
      actual-budget = enabled // {
        domain = homeDomain;
      };

      forgejo = enabled // {
        domain = homeDomain;
      };

      gatus = enabled // {
        inherit domain;
        configFile = ./gatus.json;
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
        grafana = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      plausible = enabled // {
        baseUrl = domain;
        secretKeybaseFile = config.sops.secrets.plausible-secret.path;
      };

      postgres = enabled;

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
        services =
          let
            inherit (config.${namespace}.services.tailscale) tailnet;
            nova = "nova.${tailnet}";
            vortex = "vortex.${tailnet}";
          in
          {
            cadvisor.url = "http://${nova}:8081";
            dns.url = "http://adguard.${tailnet}";
            home.url = "http://homeassistant.${tailnet}:8123";
            image.url = "http://${nova}:3474";
            map.url = "http://${vortex}:81";
            paperless = {
              url = "http://${nova}:8010";
              useAuth = false;
            };
            pdf = {
              url = "http://${nova}:8087";
              useAuth = false;
            };
            photos = {
              url = "http://${nova}:8086";
              useAuth = false;
            };
            prometheus.url = "http://${nova}:9090";
            prowlarr.url = "http://${nova}:9696";
            qbit.url = "http://${nova}:8080";
            read.url = "http://${nova}:5000";
            readarr.url = "http://${nova}:8787";
            restic.url = "http://${nova}:9898";
            radarr.url = "http://${nova}:7878";
            rss = {
              url = "http://${nova}:5600";
              useAuth = false;
            };
            sonarr.url = "http://${nova}:8989";
            stream = {
              url = "http://${nova}:8096";
              useAuth = false;
              middlewares = [ "jellyfin-redirect" ];
            };
            unraid = {
              url = "https://${nova}";
              useInsecure = true;
            };
          };
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

  system.stateVersion = "24.11";
}
