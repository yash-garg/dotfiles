_: {
  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Cursor"
      "Spotify"
      "Android Studio"
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
        "cursor"
        "discord"
        "flutter"
        "notion-calendar"
        "obsidian"
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

  environment.variables = {
    SSH_AUTH_SOCK = "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
  };

  system.stateVersion = 5;
}
