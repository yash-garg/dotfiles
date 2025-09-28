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
  cfg = config.${namespace}.system.wsl;
in
{
  options.${namespace}.system.wsl = with types; {
    enable = mkBoolOpt false "Whether or not to enable WSL support";
    hostname = mkOpt types.str "" "The hostname of the WSL instance";
    user = mkOpt types.str "yash" "The default user for the WSL instance";
  };

  config = mkIf cfg.enable {
    wsl = enabled // {
      defaultUser = cfg.user;
      startMenuLaunchers = true;
      usbip = enabled;
      wslConf.network.hostname = cfg.hostname;

      # Binaries for Docker Desktop wsl-distro-proxy
      extraBin = with pkgs; [
        { src = "${coreutils}/bin/mkdir"; }
        { src = "${coreutils}/bin/cat"; }
        { src = "${coreutils}/bin/whoami"; }
        { src = "${coreutils}/bin/ls"; }
        { src = "${busybox}/bin/addgroup"; }
        { src = "${su}/bin/groupadd"; }
        { src = "${su}/bin/usermod"; }
      ];
    };
  };
}
