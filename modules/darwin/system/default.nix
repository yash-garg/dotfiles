_: {
  system = {
    defaults = {
      controlcenter = {
        BatteryShowPercentage = true;
        NowPlaying = false;
      };

      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        NSGlobalDomain.AppleActionOnDoubleClick = "Minimize";
      };

      ".GlobalPreferences"."com.apple.mouse.scaling" = -1.0;

      loginwindow.GuestEnabled = false;

      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.trackpad.forceClick" = true;
        ApplePressAndHoldEnabled = false;
        AppleInterfaceStyle = null;
        AppleInterfaceStyleSwitchesAutomatically = true;
        AppleScrollerPagingBehavior = true;
        AppleWindowTabbingMode = "always";
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      screencapture = {
        disable-shadow = false;
        show-thumbnail = false;
        type = "png";
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };
    };

    startup.chime = true;
  };
}
