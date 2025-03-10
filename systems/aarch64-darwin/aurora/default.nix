{ config, namespace, ... }:
{
  dots = {
    dock.persistentApps = [
      "Linear"
      "Google Chrome"
      "OrbStack"
      "zoom.us"
    ];

    homebrew.additionalCasks = [
      "linear-linear"
    ];

    user.name = "ygarg";
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
