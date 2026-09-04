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
      sopsFile = lib.dots.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = lib.dots.get-file "secrets/tailscale.yaml";
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
      inherit hostName;
    };

    services = {
      caddy = enabled // {
        auth = enabled // {
          url = "http://zenith.turtle-lake.ts.net:${toString ports.authelia}";
        };
        internal = enabled;
      };

      minecraft-server = enabled // {
        backup = enabled;
        proxy = enabled;
      };

      monitoring = enabled // {
        alloy = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      restic = enabled;

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        ssh = true;
      };
    };

    virtualisation = enabled;
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" ];
  };

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

  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "26.05";
}
