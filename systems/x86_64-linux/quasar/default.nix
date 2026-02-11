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
  hostName = "quasar";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };

    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
  };

  dots = {
    hardware.networking = enabled // {
      inherit hostName;
      tcpPorts = [ 22 ];
    };

    server = enabled;

    services = {
      arr-stack = enabled // {
        mediaDirs = [
          "/mnt/media/main"
          "/mnt/media/samsung"
          "/mnt/media/wd"
        ];
      };

      bentopdf = enabled;

      calibre-web = enabled // {
        mediaDir = "/mnt/books";
      };

      copyparty = enabled // {
        user = "yash";
        group = "users";
        waitForMounts = [
          "mnt-books.mount"
          "mnt-documents.mount"
          "mnt-media-main-movies.mount"
          "mnt-media-main-tv.mount"
          "mnt-media-samsung.mount"
          "mnt-media-wd.mount"
          "mnt-photos.mount"
        ];
        volumes =
          let
            defaultAccess = {
              r.wmda = "yash";
            };
          in
          {
            "/books" = {
              path = "/mnt/books";
              access = defaultAccess;
            };
            "/documents" = {
              path = "/mnt/documents/documents/originals";
              access = defaultAccess;
            };
            "/downloads" = {
              path = "/mnt/downloads";
              access = defaultAccess;
            };
            "/media" = {
              path = "/mnt/media";
              access = defaultAccess;
            };
            "/photos" = {
              path = "/mnt/photos";
              access = defaultAccess;
            };
          };
      };

      immich = enabled // {
        backup = enabled;
        mediaDir = "/mnt/photos";
      };

      mealie = enabled;

      miniflux = enabled;

      monitoring = enabled // {
        alloy = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      nvidia-exporter = enabled;

      paperless = enabled // {
        backup = enabled;
        mediaDir = "/mnt/documents/";
      };

      postgres = enabled // {
        package = pkgs.postgresql_16;
      };

      restic = enabled;

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = true;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        exitNode = true;
        ssh = true;
        subnetRouting = enabled // {
          routes = [
            "10.0.0.0/24"
            "10.0.1.0/24"
          ];
        };
      };
    };

    system.boot = enabled // {
      secure = disabled;
      timeout = 1;
    };
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

  systemd.targets.multi-user.enable = true;

  users = {
    mutableUsers = false;
    users.yash = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user-password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      ignoreShellProgramCheck = true;
    };
  };

  system.stateVersion = "26.05";
}
