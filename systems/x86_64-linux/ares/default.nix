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
  hostName = "ares";
in
{
  imports = [
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

  boot.loader.grub = enabled // {
    device = "/dev/vda";
  };

  dots = {
    hardware.networking = enabled // {
      inherit hostName;
      extra = true;
      tcpPorts = [ 22 ];
    };

    services = {
      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = true;
        permitRootLogin = true;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        exitNode = true;
        ssh = true;
      };
    };
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
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

  system.stateVersion = "26.05";
}
