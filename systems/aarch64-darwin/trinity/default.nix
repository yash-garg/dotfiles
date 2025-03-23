_: {
  dots = {
    dock.persistentApps = [
      "ChatGPT"
      "Discord"
      "Arc"
      "WhatsApp"
      "Telegram"
    ];

    homebrew = {
      additionalCasks = [
        "arc"
        "chatgpt"
        "discord"
        "slack"
        "transmission"
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

  system.stateVersion = 5;
}
