{ lib, namespace, ... }:
with lib;
with lib.${namespace};
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  dots = {
    hardware = {
      networking = enabled;
    };

    services = {
      ssh = enabled;
    };

    system = {
      boot = enabled;
      xkb = enabled;
    };
  };

  users.users.yash = {
    group = "users";
    isNormalUser = true;
  };

  system.stateVersion = "26.05";
}
