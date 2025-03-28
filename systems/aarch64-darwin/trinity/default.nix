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
        "claude"
        "discord"
        "notion-calendar"
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

  # Uncomment after https://github.com/bitwarden/clients/issues/13075#issuecomment-2708826428
  # environment.variables = {
  #   SSH_AUTH_SOCK = "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
  # };

  system.stateVersion = 5;
}
