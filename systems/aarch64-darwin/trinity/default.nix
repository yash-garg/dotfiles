_: {
  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Visual Studio Code"
      "Spotify"
      "Android Studio"
      "ChatGPT"
      "Slack"
      "Discord"
      "Arc"
      "WhatsApp"
      "Telegram"
    ];

    homebrew = {
      additionalCasks = [
        "actual"
        "arc"
        "chatgpt"
        "discord"
        "flutter"
        "notion-calendar"
        "obsidian"
        "slack"
        "visual-studio-code"
      ];

      masApps = {
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
