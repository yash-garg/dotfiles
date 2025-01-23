{ lib, namespace, ... }:
with lib.${namespace};
let
  casks = [
    "alt-tab"
    "arc"
    "chatgpt"
    "discord"
    "flutter"
    "ghostty"
    "iina"
    "imageoptim"
    "jetbrains-toolbox"
    "linear-linear"
    "maccy"
    "pop"
    "raycast"
    "spotify"
    "steam"
    "transmission"
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

    masApps = {
      Amphetamine = 937984704;
      Bitwarden = 1352778147;
      "Prime Video" = 545519333;
      Slack = 803453959;
      Tailscale = 1475387142;
      Telegram = 747648890;
      WhatsApp = 310633997;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };

  # Since we aren't managing graphical apps with home-manager
  # on darwin, add the config files directly in xdg config
  snowfallorg.users.yash.home.config = {
    xdg.configFile = {
      "ghostty/config".source = "${hmModules}/ghostty/config";
    };
  };
}
