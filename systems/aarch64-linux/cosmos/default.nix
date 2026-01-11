{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  hostName = "cosmos";
in
{
  imports = [ ./hardware-configuration.nix ];

  sops.secrets = {
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };

    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
  };

  boot.initrd.systemd.tpm2.enable = mkForce false;

  dots = {
    hardware.networking = enabled // {
      inherit hostName;
      extra = false;
      tcpPorts = [
        80
        90
        443
      ];
    };

    services = {
      avahi = enabled;

      samba = enabled // {
        shares = {
          media.path = "/mnt/wd500";
          evo.path = "/mnt/evo970";
        };
      };

      ssh = enabled // {
        package = pkgs.openssh_hpn;
        passwordAuth = true;
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
  };

  environment = {
    pathsToLink = [ "/share/bash-completion" ];
    systemPackages = with pkgs; [
      git
      bluez
      bluez-tools
    ];
  };

  topology.self.name = "Raspberry Pi 5";

  users = {
    mutableUsers = false;
    users.yash = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user-password.path;
      ignoreShellProgramCheck = true;
      extraGroups = [
        "docker"
        "wheel"
      ];
    };
  };

  system.stateVersion = "26.05";
}
