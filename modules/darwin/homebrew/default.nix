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
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "maccy"
    "orbstack"
    "raycast"
    "spotify"
  ]
  ++ cfg.additionalCasks;
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

    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of additional brews to install.
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
      inherit (cfg) masApps;

      brews = [
        "cocoapods"
        "ruby"
        "webp"
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
