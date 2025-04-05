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
  cfg = config.${namespace}.desktop;
in
{
  options.${namespace}.desktop = {
    enable = mkEnableOption "Profile for desktop machines";

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to install on desktop machines";
    };
  };

  config = mkIf cfg.enable {
    # Common configuration for desktop machines
    dots = {
      desktop = {
        android-dev = enabled;
        earlyoom = enabled;
        gaming = enabled;
        stylix = enabled;
      };

      hardware = {
        audio = enabled;
        bluetooth = enabled;
        networking = enabled;
      };

      services = {
        openrazer = disabled;
        printing = enabled;
        ssh = enabled;
        tailscale = enabled;
        yubikey = enabled;
      };

      system = {
        boot = enabled;
        xkb = enabled;
      };
    };

    environment.systemPackages = with pkgs; [ inetutils ];

    # Enable the X11 windowing system.
    services.xserver = enabled;

    # Common packages for desktop machines
    users.users.yash.packages =
      # CLI
      with pkgs;
      [
        caligula
        ddcutil
        git-lfs
        nh
        qemu_kvm
        sshfs
        xclip
      ]
      # GUI
      ++ (with pkgs; [
        collision
        curtail
        emblem
        foliate
        google-chrome
        handbrake
        jetbrains.idea-ultimate
        newsflash
        obsidian
        slack
        spotify
        telegram-desktop
        textpieces
        transmission_4-gtk
        vesktop
        vscode
      ])
      ++ cfg.extraPackages;
  };
}
