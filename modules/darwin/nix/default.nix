{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  environment = {
    pathsToLink = [ "/share/zsh" ];
    systemPackages = with pkgs; [
      findutils
      gawk
      gnugrep
      gnused
      gnutls
      inetutils
    ];
    systemPath = lib.mkBefore [ "/opt/homebrew/bin" ];
    variables = {
      LANG = "en_US.UTF-8";
    };

  };

  nix = mkNixConfig { inherit lib pkgs; } // {
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
  };

  # Add ability to use TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
