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
    "alt-tab"
    "flutter"
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "maccy"
    "orbstack"
    "raycast"
    "slack"
    "spotify"
    "visual-studio-code"
  ];
  cfg = config.${namespace}.homebrew;
  hmModules = lib.snowfall.fs.get-snowfall-file "modules/home";
in
{
  options.${namespace}.homebrew = {
    additionalCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of additional casks to install.
      '';
    };

    masApps = mkOption {
      type = types.attrsOf types.int;
      default = { };
      description = ''
        A map of macOS App Store apps to install.
      '';
    };
  };

  config = {
    homebrew = enabled // {
      brews = [
        "cocoapods"
        "ruby"
      ];

      casks =
        map (cask: {
          name = cask;
          greedy = true;
        }) casks
        ++ map (cask: {
          name = cask;
          greedy = true;
        }) cfg.additionalCasks;

      caskArgs.appdir = "/Applications";

      global = {
        autoUpdate = true;
        brewfile = true;
      };

      taps = [ ];

      inherit (cfg) masApps;

      onActivation = {
        autoUpdate = false;
        cleanup = "zap";
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
