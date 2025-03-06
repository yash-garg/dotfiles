{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.dock;
in
{
  options.${namespace}.dock = {
    persistentApps = mkOption {
      type = types.listOf types.str;
      description = ''
        A list of applications to appear in the persistent dock.
      '';
    };
  };

  config = {
    system.defaults.dock = {
      autohide = true;
      largesize = 110;
      magnification = true;
      mineffect = "scale";
      minimize-to-application = false;
      orientation = "bottom";
      persistent-apps =
        let
          brewAppDir = config.homebrew.caskArgs.appdir;
          sysAppDir = "/System/Applications";
        in
        [
          "${sysAppDir}/Launchpad.app"
          "${brewAppDir}/Ghostty.app"
          "${brewAppDir}/Linear.app"
          "${brewAppDir}/Xcode.app"
          "${brewAppDir}/Visual Studio Code.app"
        ]
        ++ cfg.persistentApps;
      show-recents = false;
      tilesize = 35;

      # Disable all hot corners
      wvous-tl-corner = 1;
      wvous-bl-corner = 1;
      wvous-tr-corner = 1;
      wvous-br-corner = 1;
    };
  };
}
