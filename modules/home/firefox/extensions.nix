{ lib, pkgs, ... }:
{
  programs.firefox.profiles.yash.extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
    betterttv
    bitwarden
    darkreader
    (buildFirefoxXpiAddon {
      pname = "dark-space-full-transparent";
      version = "1.3";
      addonId = "{24aca621-5029-4aa4-95a9-81d4bd3eba76}";
      url = "https://addons.mozilla.org/firefox/downloads/file/3888121/dark_space_full_transparent-1.3.xpi";
      sha256 = "sha256-63emiqUdRBPIYnqXX7aftmNIs4TF5aWXKj0Fn/xnTng=";
      meta = with lib; {
        platforms = platforms.all;
      };
    })
    keepa
    (buildFirefoxXpiAddon {
      pname = "material-icons-for-github";
      version = "1.8.23";
      addonId = "{eac6e624-97fa-4f28-9d24-c06c9b8aa713}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4326942/material_icons_for_github-1.8.23.xpi";
      sha256 = "sha256-Pee0D0bUCmIB5P4GvwIa8NRXuKzW1LpIpKJSMXVNWbg=";
      meta = with lib; {
        platforms = platforms.all;
      };
    })
    multi-account-containers
    protondb-for-steam
    raindropio
    return-youtube-dislikes
    sponsorblock
    steam-database
    ublock-origin
  ];
}
