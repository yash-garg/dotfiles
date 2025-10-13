{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  casks = [
    "domzilla-caffeine"
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "maccy"
    "orbstack"
    "raycast"
    "spotify"
    "swiftformat-for-xcode"
  ]
  ++ cfg.additionalCasks;
  cfg = config.${namespace}.homebrew;
  hmModules = lib.snowfall.fs.get-snowfall-file "modules/home";
in
{
  options.${namespace}.homebrew = {
    additionalCasks = mkOpt (types.listOf types.str) [ ] "A list of additional casks to install.";
    brews = mkOpt (types.listOf types.str) [ ] "A list of additional brews to install.";
    masApps = mkOpt (types.attrsOf types.int) { } "A map of macOS App Store apps to install.";
  };

  config = {
    homebrew = enabled // {
      inherit (cfg) masApps;

      brews = [
        "cocoapods"
        "ruby"
        "swiftformat"
        "webp"
        "xcbeautify"
        {
          name = "JakeWharton/repo/diffuse";
          args = [ "ignore-dependencies" ];
        }
      ]
      ++ cfg.brews;

      caskArgs.appdir = "/Applications";

      casks = map (cask: {
        name = cask;
        greedy = true;
      }) casks;

      greedyCasks = false;

      global = {
        autoUpdate = true;
        brewfile = true;
      };

      onActivation = {
        autoUpdate = false;
        cleanup = "zap";
        extraFlags = [ "--verbose" ];
        upgrade = true;
      };
    };

    # Since we aren't managing graphical apps with home-manager
    # on darwin, add the config files directly in xdg config
    snowfallorg.users.${config.${namespace}.user.name}.home.config = {
      xdg.configFile = {
        "ghostty/config".source = "${hmModules}/ghostty/config";
      };
    };
  };
}
