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
    wireguard-key = {
      sopsFile = snowfall.fs.get-file "secrets/wireguard.yaml";
      key = "vortex-privkey";
      mode = "0400";
    };
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

  networking.firewall.allowedUDPPorts = [ ports.wireguard ];
  networking.wg-quick.interfaces.wg0 = {
    address = [
      "fd00:100::2/64"
      "2a0c:9a40:8913:0::1/64"
    ];
    privateKeyFile = config.sops.secrets.wireguard-key.path;
    peers = [
      {
        publicKey = "XPTZ/mSeFBK7ekDSX/FjqJ411MWQB+M59SKbO/wjyUU=";
        endpoint = "[2401:c080:3400:224f:5400:05ff:feef:f172]:${toString ports.wireguard}";
        allowedIPs = [ "fd00:100::1/128" ];
        persistentKeepalive = 25;
      }
    ];
  };

  dots = {
    server = enabled;

    hardware.networking = enabled // {
      inherit hostName;
      ports = [
        80
        443
      ];
    };

    services = {
      caddy = enabled // {
        auth = enabled // {
          url = "http://zenith.turtle-lake.ts.net:${toString ports.authelia}";
        };
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
        acceptRoutes = true;
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
