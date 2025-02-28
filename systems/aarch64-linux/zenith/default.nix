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
    cloudflared = {
      file = get-secret "cloudflared.json";
      owner = config.services.cloudflared.user;
      group = config.services.cloudflared.group;
    };
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
  };

  services = {
    actual = enabled // {
      openFirewall = true;
      settings = {
        hostname = "finance.yashgarg.dev";
        port = 4000;
      };
    };

    cloudflared = enabled // {
      tunnels = {
        "cfb054a0-f0d9-4a2f-97b8-d659b1da4498" = {
          credentialsFile = config.age.secrets.cloudflared.path;
          ingress = {
            "analytics.yashgarg.dev" = {
              service = "http://localhost:8181";
            };
            "finance.yashgarg.dev" = {
              service = "http://localhost:4000";
            };
          };
          default = "http_status:404";
        };
      };
    };
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
