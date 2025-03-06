{ config, namespace, ... }:
let
  username = config.${namespace}.user.name;
in
{
  dots = {
    dock.persistentApps =
      let
        brewAppDir = config.homebrew.caskArgs.appdir;
        homeAppDir = "${config.users.users.${username}.home}/Applications";
      in
      [
        "${brewAppDir}/Spotify.app"
        "${brewAppDir}/Linear.app"
        "${homeAppDir}/Android Studio.app"
        "${brewAppDir}/Google Chrome.app"
        "${brewAppDir}/OrbStack.app"
        "${brewAppDir}/Slack.app"
        "${brewAppDir}/zoom.us.app"
      ];

    homebrew.additionalCasks = [
      "linear-linear"
    ];

    user.name = "ygarg";
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
