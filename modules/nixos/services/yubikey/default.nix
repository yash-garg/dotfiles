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
  cfg = config.${namespace}.services.yubikey;
in
{
  options.${namespace}.services.yubikey = {
    enable = mkEnableOption "Enable yubikey support";
  };

  config = mkIf cfg.enable {
    security.pam = {
      sshAgentAuth = enabled;
      services = {
        login.u2fAuth = true;
        sudo = {
          u2fAuth = true;
          sshAgentAuth = true;
        };
      };
      u2f = enabled // {
        settings.cue = false;
      };
    };

    services = {
      pcscd = enabled;
      udev.packages = [ pkgs.yubikey-personalization ];
      yubikey-agent = enabled;
    };

    users.users.yash.packages = with pkgs; [
      pam_u2f
      yubikey-manager
      yubioath-flutter
    ];
  };
}
