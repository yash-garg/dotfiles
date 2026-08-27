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
  cfg = config.profiles.${namespace}.gpg;
in
{
  options.profiles.${namespace}.gpg = {
    enable = mkEnableOption "Enable GPG and Pinentry agents";
  };

  config = mkIf cfg.enable {
    programs.gpg = enabled // {
      settings = {
        auto-key-locate = "nodefault,wkd";
      };
      scdaemonSettings = {
        disable-ccid = true;
      };
    };

    services.gpg-agent = enabled // {
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = mkMerge [
        (mkIf pkgs.stdenv.hostPlatform.isLinux pkgs.pinentry-gnome3)
        (mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.pinentry_mac)
      ];
    };
  };
}
