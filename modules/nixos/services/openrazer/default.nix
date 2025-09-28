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
  cfg = config.${namespace}.services.openrazer;
in
{
  options.${namespace}.services.openrazer = {
    enable = mkEnableOption { description = "Whether to configure openrazer settings"; };
    users = mkOpt (types.listOf types.str) [ "yash" ] "List of users to add to the openrazer group";
    gui = mkBoolOpt false "Whether to enable the polychromatic GUI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.openrazer-daemon ];

    hardware.openrazer = enabled // {
      inherit (cfg) users;
      batteryNotifier = disabled;
      devicesOffOnScreensaver = false;
      syncEffectsEnabled = false;
    };

    users.users.yash.packages = mkIf cfg.gui [ pkgs.polychromatic ];
  };
}
