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
  hostName = "vortex";
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

    services = {
      minecraft-server = enabled;

      prometheus = enabled;

      restic = enabled;

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
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
