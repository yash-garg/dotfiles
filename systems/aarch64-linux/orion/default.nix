{
  pkgs,
  lib,
  namespace,
  modulesPath,
  ...
}:
with lib;
with lib.${namespace};
let
  hostName = "orion";
in
{
  imports = [
    # Include the default lxd configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"
    # Include the OrbStack-specific configuration.
    ./orbstack.nix
  ];

  dots = {
    server = enabled;
    services = {
      ssh = disabled;
    };
  };

  networking = {
    inherit hostName;
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  programs.nix-ld = enabled // {
    package = pkgs.nix-ld-rs;
  };

  systemd.network = enabled // {
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    # This being `true` leads to a few nasty bugs, change at your own risk!
    mutableUsers = false;
    users.yash = {
      uid = 501;
      extraGroups = [
        "wheel"
        "orbstack"
      ];
      isNormalUser = false;
      isSystemUser = true;
      group = "users";
      createHome = true;
      home = "/home/yash";
      homeMode = "700";
      useDefaultShell = true;
    };
  };

  system.stateVersion = "25.05";
}
