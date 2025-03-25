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
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "maccy"
    "orbstack"
    "raycast"
    "spotify"
    "visual-studio-code"
  ] ++ cfg.additionalCasks;
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

    taps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of additional taps to add.
      '';
    };
  };

  config = {
    homebrew = enabled // {
      inherit (cfg) masApps;

      brews = [
        "cocoapods"
        "ruby"
      ];

      caskArgs.appdir = "/Applications";

      casks = map (cask: {
        name = cask;
        greedy = true;
      }) casks;

      global = {
        autoUpdate = true;
        brewfile = true;
      };

      inherit (cfg) taps;

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
