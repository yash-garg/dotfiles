{
  lib,
  config,
  namespace,
  ...
}:
with lib.${namespace};
let
  casks = [
    "alt-tab"
    "flutter"
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "linear-linear"
    "maccy"
    "orbstack"
    "raycast"
    "slack"
    "spotify"
    "visual-studio-code"
    "zed"
  ];
  hmModules = lib.snowfall.fs.get-snowfall-file "modules/home";
in
{
  homebrew = enabled // {
    brews = [
      "cocoapods"
      "ruby"
    ];

    casks = map (cask: {
      name = cask;
      greedy = true;
    }) casks;

    caskArgs.appdir = "/Applications";

    global = {
      autoUpdate = true;
      brewfile = true;
    };

    taps = [ ];

    masApps = { };

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
}
