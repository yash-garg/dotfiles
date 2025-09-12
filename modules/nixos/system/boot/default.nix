{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.boot;
in
{
  options.${namespace}.system.boot = with types; {
    enable = mkBoolOpt false "Whether or not to enable booting";

    secure = {
      enable = mkBoolOpt false "Enable Secure Boot";
      pkiBundle = mkOption {
        type = str;
        default = "/etc/secureboot";
        description = "The path to the PKI bundle";
      };
    };
  };

  config = mkIf cfg.enable {
    boot = {
      initrd.systemd = enabled;

      # Use latest kernel by default.
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Secure Boot
      lanzaboote = {
        inherit (cfg.secure) enable;
        inherit (cfg.secure) pkiBundle;
      };

      # Bootloader
      loader = {
        efi = {
          efiSysMountPoint = "/boot";
          # Set to true only the first time
          canTouchEfiVariables = false;
        };

        systemd-boot.enable = mkForce (!cfg.secure.enable);
        timeout = mkDefault 60;
      };
    };
  };
}
