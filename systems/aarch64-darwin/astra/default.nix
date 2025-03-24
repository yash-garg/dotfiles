_: {
  dots = {
    dock.persistentApps = [
      "Firefox"
      "Google Chrome"
      "OrbStack"
    ];

    homebrew = {
      additionalCasks = [
        "firefox@beta"
        "google-chrome"
        "notion-calendar"
      ];

      brews = [
        "gpg"
        "pinentry-mac"
      ];

      masApps = {
        Amphetamine = 937984704;
        Bitwarden = 1352778147;
      };
    };
  };

  system.stateVersion = 5;
}
