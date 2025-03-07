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
        "${brewAppDir}/ChatGPT.app"
        "${brewAppDir}/Discord.app"
        "${brewAppDir}/Spotify.app"
        "${brewAppDir}/Arc.app"
        "${homeAppDir}/Android Studio.app"
        "${brewAppDir}/WhatsApp.app"
        "${brewAppDir}/Slack.app"
        "${brewAppDir}/Telegram.app"
        "${brewAppDir}/Unread.app"
      ];

    homebrew = {
      additionalCasks = [
        "arc"
        "chatgpt"
        "discord"
      ];

      masApps = {
        Amphetamine = 937984704;
        Bitwarden = 1352778147;
        "Prime Video" = 545519333;
        Tailscale = 1475387142;
        Telegram = 747648890;
        Unread = 1363637349;
        WhatsApp = 310633997;
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
