{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  username = config.${namespace}.user.name;
in
{
  sops.secrets.gitconfig = {
    sopsFile = snowfall.fs.get-file "secrets/.gitconfig-work";
    format = "binary";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Spotify"
      "Google Chrome"
      "Android Studio"
      "OrbStack"
      "Windsurf - Next"
    ];

    homebrew = {
      additionalCasks = [
        "google-chrome"
        "windsurf@next"
      ];

      brews = [
        "cloudflared"
        "openjdk@21"
        "swiftformat"
        "xcode-build-server"
        "xcode-kotlin"
        "vault"
      ];
    };

    user.name = "ygarg";
  };

  homebrew.taps = [
    "anomalyco/tap"
    "hashicorp/tap"
  ];

  snowfallorg.users.${username}.home.config = {
    programs.git.includes = mkAfter [
      { inherit (config.sops.secrets.gitconfig) path; }
    ];
  };

  system.stateVersion = 6;
}
