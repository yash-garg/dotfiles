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

    services.gpg-agent = {
      enable = pkgs.stdenv.isLinux;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    home.file.".gnupg/gpg-agent.conf" = {
      enable = pkgs.stdenv.isDarwin;
      text = ''
        pinentry-program ${getExe pkgs.pinentry_mac}
        enable-ssh-support
      '';
    };
  };
}
