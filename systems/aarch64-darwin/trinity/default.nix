_: {
  dots.homebrew = {
    additionalCasks = [
      "arc"
      "chatgpt"
      "discord"
      "steam"
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

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
