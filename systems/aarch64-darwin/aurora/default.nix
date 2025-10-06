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
      "Android Studio"
      "Slack"
      "Arc"
      "OrbStack"
      "Zed"
    ];

    homebrew = {
      additionalCasks = [
        "arc"
        "flutter"
        "slack"
        "windsurf@next"
        "zed"
        "zoom"
      ];

      brews = [
        "cloudflared"
        "openjdk@21"
        "swiftformat"
        "xcode-build-server"
      ];
    };

    user.name = "ygarg";
  };

  snowfallorg.users.${username}.home.config = {
    programs.git.includes = mkAfter [
      { inherit (config.sops.secrets.gitconfig) path; }
    ];
  };

  system.stateVersion = 5;
}
