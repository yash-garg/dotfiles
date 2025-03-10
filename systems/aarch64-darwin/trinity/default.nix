{ config, namespace, ... }:
{
  dots = {
    dock.persistentApps = [
      "ChatGPT"
      "Discord"
      "Arc"
      "WhatsApp"
      "Telegram"
      "Unread"
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
