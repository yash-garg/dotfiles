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
    sopsFile = lib.dots.get-file "secrets/.gitconfig-work";
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
        "zed"
      ];

      brews = [
        "cloudflared"
        "openjdk"
        "node@22"
        "sipp"
        "socat"
        "swiftformat"
        "xcode-build-server"
        "xcode-kotlin"
        "vault"
        "yarn"
      ];
    };

    user.name = "ygarg";
  };

  homebrew.taps = [
    {
      name = "anomalyco/tap";
      trusted = true;
    }
    {
      name = "hashicorp/tap";
      trusted = true;
    }
  ];

  home-manager.users.${username} = {
    programs.git.includes = mkAfter [
      { inherit (config.sops.secrets.gitconfig) path; }
    ];
  };

  system.stateVersion = 6;
}
