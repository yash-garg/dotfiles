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
  hostName = "zenith";
  inherit (config.${namespace}.services.tailscale) tailnet;
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./traefik.nix
  ];

  age.secrets = {
    user-password.file = getSecret "user" hostName;
    plausible.file = getSecret "plausible" hostName;
    tsauthkey.file = getSecret "tailscale" hostName;
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
    firewall.allowedTCPPorts = [
      80
      443
    ];
    networkmanager = enabled;
    inherit hostName;
  };

  dots = {
    server = enabled;

    sso = enabled // {
      domain = "ipx.ovh";
    };

    services = {
      gatus = enabled // {
        inherit domain;
        monitorPoints = [
          {
            name = "Actual Budget";
            url = "http://vortex.${tailnet}:5006";
          }
          {
            name = "Cadvisor";
            url = "http://nova.turtle-lake.ts.net";
          }
          {
            name = "Grafana";
            url = "http://nova.${tailnet}:3000";
          }
          {
            name = "Home Assistant";
            url = "http://homeassistant.${tailnet}:8123";
          }
          {
            name = "Jellyfin";
            url = "http://nova.${tailnet}:8096";
          }
          {
            name = "Mazanoke";
            url = "http://nova.${tailnet}:3474";
          }
          {
            name = "Miniflux";
            url = "http://nova.${tailnet}:5600";
          }
          {
            name = "Minecraft Map";
            url = "http://vortex.${tailnet}:81";
          }
          {
            name = "NVR";
            url = "http://nova.${tailnet}:1984";
          }
          {
            name = "Prometheus";
            url = "http://nova.${tailnet}:9090";
          }
          {
            name = "Plausible Analytics";
            url = "http://localhost:8181";
          }
          {
            name = "Prowlarr";
            url = "http://nova.${tailnet}:9696";
          }
          {
            name = "Radarr";
            url = "http://nova.${tailnet}:7878";
          }
          {
            name = "Sonarr";
            url = "http://nova.${tailnet}:8989";
          }
          {
            name = "qBittorrent";
            url = "http://nova.${tailnet}:8080";
          }
          {
            name = "unRAID";
            url = "http://nova.${tailnet}";
          }
        ];
      };

      linkding = enabled // {
        port = 9095;
        proxy = enabled // {
          domain = "ipx.ovh";
        };
      };

      plausible = enabled // {
        baseUrl = domain;
        secretKeybaseFile = config.age.secrets.plausible.path;
      };

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
      };

      tailscale = enabled // {
        authKeyFile = config.age.secrets.tsauthkey.path;
        exitNode = true;
        ssh = true;
        subnetRouting = enabled // {
          routes = [
            "192.168.0.0/24"
            "192.168.1.0/24"
          ];
        };
      };
    };

    virtualisation = enabled;
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.user-password.path;
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
