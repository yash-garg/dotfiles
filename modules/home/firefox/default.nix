{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.firefox;
  css-hacks = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "9a9dd88871104528422ada76ebb7e35ca3c2bc6b";
    sha256 = "sha256-e0NRl02detYub0abhe8glRgokyHdyt9Hxc8rSTYanEw=";
  };
in
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./settings.nix
  ];

  options.profiles.${namespace}.firefox = {
    enable = mkEnableOption "Enable firefox profile";
  };

  config = mkIf cfg.enable {
    programs.firefox = enabled // {
      package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { };
      profiles = {
        yash = {
          isDefault = true;
          search = {
            force = true;
            default = "google";
            privateDefault = "google";
            engines = {
              "bing".metaData.hidden = true;
              "ddg".metaData.hidden = true;
              "wikipedia".metaData.hidden = true;

              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
            };
          };
          userChrome = ''
            @import url("${css-hacks}/chrome/auto_devtools_theme_for_rdm.css");
            @import url("${css-hacks}/chrome/compact_extensions_panel.css");
            @import url("${css-hacks}/chrome/tabs_on_bottom.css");
            @import url("${css-hacks}/chrome/tabs_on_bottom_menubar_on_top_patch.css");
          '';
        };
      };
    };
  };
}
