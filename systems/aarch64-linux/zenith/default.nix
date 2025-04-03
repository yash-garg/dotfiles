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
  hostName = "zenith";
  get-secret = name: snowfall.fs.get-file "secrets/${hostName}/${name}.age";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  age.secrets = {
    cloudflared.file = get-secret "cloudflared";
    homepage.file = get-secret "homepage.env";
    user-password.file = get-secret "user";
    plausible.file = get-secret "plausible";
    tsauthkey.file = get-secret "tailscale";
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
    networkmanager = enabled;
    inherit hostName;
  };

  dots = {
    server = enabled;

    services = {
      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
      };

      tailscale = enabled // {
        authKeyFile = config.age.secrets.tsauthkey.path;
        extraOptions = [
          "--accept-risk=lose-ssh"
          "--advertise-exit-node"
          "--advertise-routes=192.168.0.0/24,192.168.1.0/24"
          "--ssh"
        ];
      };

      plausible = enabled // {
        baseUrl = "analytics.yashgarg.dev";
        secretKeybaseFile = config.age.secrets.plausible.path;
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

  virtualisation.oci-containers.containers.cloudflared-tunnel = {
    image = "cloudflare/cloudflared:latest";
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    extraOptions = [
      "--network"
      "host"
    ];
    environmentFiles = [ config.age.secrets.cloudflared.path ];
  };

  # TODO: Move this to separate module later.
  services.homepage-dashboard = enabled // {
    environmentFile = config.age.secrets.homepage.path;
    listenPort = 3000;
    openFirewall = true;
    settings = {
      title = "Yash's Homelab";
      description = "A collection of services running on my homelab.";
      favicon = "https://yashgarg.dev/favicon.ico";
      theme = "dark";
    };
    bookmarks = [
      {
        "Development" = [
          {
            "Calendar" = [
              {
                icon = "si-notion";
                href = "https://calendar.notion.so/";
              }
            ];
          }
          {
            "Github" = [
              {
                icon = "si-github";
                href = "https://github.com/";
              }
            ];
          }
          {
            "NixOS Search" = [
              {
                icon = "si-nixos";
                href = "https://search.nixos.org/packages";
              }
            ];
          }
          {
            "Tailscale" = [
              {
                icon = "si-tailscale";
                href = "https://login.tailscale.com/admin/machines";
              }
            ];
            "Raindrop" = [
              {
                icon = "si-icloud";
                href = "https://raindrop.io/";
              }
            ];
          }
        ];
      }
      {
        "Social" = [
          {
            "Reddit" = [
              {
                icon = "si-reddit";
                href = "https://reddit.com/";
              }
            ];
          }
          {
            "LinkedIn" = [
              {
                icon = "si-linkedin";
                href = "https://linkedin.com/";
              }
            ];
          }
          {
            "Twitter" = [
              {
                icon = "si-twitter";
                href = "https://x.com/";
              }
            ];
          }
          {
            "Mastodon" = [
              {
                icon = "si-mastodon";
                href = "https://elk.zone/";
              }
            ];
          }
          {
            "Pinterest" = [
              {
                icon = "si-pinterest";
                href = "https://pinterest.com/";
              }
            ];
          }
        ];
      }
      {
        "Entertainment" = [
          {
            "Netflix" = [
              {
                icon = "si-netflix";
                href = "https://netflix.com/";
              }
            ];
          }
          {
            "Spotify" = [
              {
                icon = "si-spotify";
                href = "https://spotify.com/";
              }
            ];
          }
          {
            "YouTube" = [
              {
                icon = "si-youtube";
                href = "https://youtube.com/";
              }
            ];
          }
        ];
      }
    ];
    # - https://map.yashgarg.dev
    # - https://actual.yashgarg.dev
    # - https://mc.yashgarg.dev
    # - jellyfin
    # - miniflux
    # - qbit
    # - h5ai
    # - home assistant
    # - pi hole
    # above services we need to categorize and place
    # use proper groups below
    services = [
      {
        "Utility" = [
          {
            "PiHole" = {
              icon = "pi-hole.png";
              href = "{{HOMEPAGE_VAR_PIHOLE_URL}}/admin/";
              description = "Adblocker for the network";
              widget = {
                type = "pihole";
                url = "{{HOMEPAGE_VAR_PIHOLE_URL}}";
                version = "6";
                key = "{{HOMEPAGE_VAR_PIHOLE_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        "Media" = [
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
              description = "Media server";
              widget = {
                type = "jellyfin";
                url = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
              };
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          cputemp = true;
          uptime = true;
          expanded = true;
        };
      }
    ];
  };

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.11";
}
