{ config, namespace, ... }:
let
  username = config.${namespace}.user.name;
in
{
  system.defaults.dock = {
    autohide = true;
    largesize = 110;
    magnification = true;
    mineffect = "scale";
    minimize-to-application = false;
    orientation = "bottom";
    persistent-apps =
      let
        brewAppDir = config.homebrew.caskArgs.appdir;
        homeAppDir = "${config.users.users.${username}.home}/Applications";
        sysAppDir = "/System/Applications";
      in
      [
        "${sysAppDir}/Launchpad.app"
        "${brewAppDir}/Ghostty.app"
        "${brewAppDir}/Linear.app"
        "${brewAppDir}/Xcode.app"
        # "${brewAppDir}/ChatGPT.app"
        "${brewAppDir}/Visual Studio Code.app"
        # "${brewAppDir}/Discord.app"
        "${brewAppDir}/Spotify.app"
        "${homeAppDir}/Android Studio.app"
        "${brewAppDir}/Google Chrome.app"
        # "${brewAppDir}/WhatsApp.app"
        "${brewAppDir}/OrbStack.app"
        "${brewAppDir}/Slack.app"
        # "${brewAppDir}/Telegram.app"
        # "${brewAppDir}/Unread.app"
        "${brewAppDir}/zoom.us.app"
      ];
    show-recents = false;
    tilesize = 35;
    # Disable all hot corners
    wvous-tl-corner = 1;
    wvous-bl-corner = 1;
    wvous-tr-corner = 1;
    wvous-br-corner = 1;
  };
}
