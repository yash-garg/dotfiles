{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  username = config.${namespace}.user.name;
in
{
  security.pki.certificateFiles = [ "/etc/nix/macos-keychain.crt" ];

  sops.secrets.gitconfig = {
    sopsFile = lib.dots.get-file "secrets/.gitconfig-work";
    format = "binary";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Spotify"
      "Google Chrome"
      "Android Studio"
      "OrbStack"
      "Windsurf - Next"
    ];

    homebrew = {
      additionalCasks = [
        "codex"
        "google-chrome"
        "moonfin"
        "windsurf@next"
        "zed"
      ];

      brews = [
        "baresip"
        "caupain"
        "cloudflared"
        "delve"
        "diffuse"
        "glab"
        "go"
        "golanci-lint"
        "openjdk"
        "nvm"
        "sipp"
        "socat"
        "xcode-build-server"
        "xcode-kotlin"
        "vault"
        "yarn"
      ];
    };

    user.name = "ygarg";
  };

  homebrew.taps = [
    {
      name = "hashicorp/tap";
      trusted = true;
    }
    {
      name = "deezer/repo";
      trusted = true;
    }
    {
      name = "jakewharton/repo";
      trusted = true;
    }
  ];

  home-manager.users.${username} = {
    programs.git.includes = mkAfter [
      { inherit (config.sops.secrets.gitconfig) path; }
    ];

    programs.zsh.initContent = mkAfter ''
      export NVM_DIR="$HOME/.nvm"
      if [ -s /opt/homebrew/opt/nvm/nvm.sh ]; then
        . /opt/homebrew/opt/nvm/nvm.sh
      fi
    '';
  };

  system.stateVersion = 6;
}
