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
  age.secrets.gitconfig = {
    file = snowfall.fs.get-file "secrets/.gitconfig-work.age";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Spotify"
      "Android Studio"
      "Linear"
      "Slack"
      "Arc"
      "OrbStack"
      "Zed"
      "zoom.us"
    ];

    homebrew = {
      additionalCasks = [
        "arc"
        "flutter"
        "linear-linear"
        "slack"
        "yubico-yubikey-manager"
        "zed"
        "zoom"
      ];

      brews = [
        "cloudflared"
        "openjdk@21"
      ];
    };

    user.name = "ygarg";
  };

  snowfallorg.users.${username}.home.config = {
    programs.git.includes = mkAfter [
      { inherit (config.age.secrets.gitconfig) path; }
    ];
  };

  system.stateVersion = 5;
}
