_: {
  dots = {
    dock.persistentApps = [
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
        "notion-calendar"
        "slack"
        "webp"
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

  environment.variables = {
    SSH_AUTH_SOCK = "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
  };

  system.stateVersion = 5;
}
