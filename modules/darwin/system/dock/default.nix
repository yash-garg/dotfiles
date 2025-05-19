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
  brewAppDir = config.homebrew.caskArgs.appdir;
in
{
  options.${namespace}.dock = {
    persistentApps = mkOption {
      default = [ ];
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
      show-recents = false;
      tilesize = 35;

      persistent-apps = [
        "/System/Applications/Launchpad.app"
      ] ++ map (app: "${brewAppDir}/${app}.app") cfg.persistentApps;

      # Disable all hot corners
      wvous-tl-corner = 1;
      wvous-bl-corner = 1;
      wvous-tr-corner = 1;
      wvous-br-corner = 1;
    };
  };
}
