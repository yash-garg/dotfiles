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
    hardware.networking = {
      inherit hostName;
      tcpPorts = [ 22 ];
    };

    server = enabled;

    services = {
      arr-stack = enabled // {
        mediaDirs = [
          "/mnt/data/media"
          "/mnt/media/samsung"
          "/mnt/media/wd"
        ];
      };

      immich = enabled // {
        mediaDir = "/mnt/data/photos";
      };

      miniflux = enabled;

      monitoring = enabled // {
        alloy = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      paperless = enabled // {
        mediaDir = "/mnt/documents/";
      };

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = true;
      };

      stirling-pdf = enabled;

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

  hardware =
    let
      driverPkg = config.boot.kernelPackages.nvidiaPackages.latest;
    in
    {
      graphics = enabled // {
        package = driverPkg;
      };
      nvidia = {
        nvidiaPersistenced = true;
        nvidiaSettings = false;
        open = true;
        package = driverPkg;
      };
    };
  services.xserver.videoDrivers = [ "nvidia" ];

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

  systemd.services.configure-gpu = {
    description = "Configure GPU power settings";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
        pkgs.writeShellApplication {
          name = "configure-gpu";
          text = ''
            # Enable persistence mode to keep the GPU initialized.
            nvidia-smi --persistence-mode=1

            # Limit power draw by default.
            nvidia-smi --power-limit=200
          '';
        }
      }/bin/configure-gpu";
    };
  };

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

  system.stateVersion = "24.11";
}
