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
      "Linear"
      "Slack"
      "Arc"
      "OrbStack"
      "zoom.us"
    ];

    homebrew = {
      additionalCasks = [
        "arc"
        "linear-linear"
        "obsidian"
        "slack"
        "temurin@21"
        "windsurf"
        "yubico-yubikey-manager"
        "zoom"
      ];

      brews = [ "cloudflared" ];
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
