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
  sops.secrets.gitconfig = {
    sopsFile = snowfall.fs.get-file "secrets/.gitconfig-personal";
    format = "binary";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Ghostty"
      "Xcode"
      "Cursor"
      "Spotify"
      "Discord"
      "Firefox"
      "OrbStack"
      "WhatsApp"
      "Telegram"
    ];

    homebrew = {
      additionalCasks = [
        "actual"
        "chatgpt"
        "chromedriver"
        "cursor"
        "discord"
        "firefox"
        "notion-calendar"
        "winbox"
      ];

      masApps = {
        Bitwarden = 1352778147;
        Tailscale = 1475387142;
        Telegram = 747648890;
        Unread = 1363637349;
        WhatsApp = 310633997;
      };
    };
  };

  environment.variables = {
    GPG_TTY = "$(tty)";
    # SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    SSH_AUTH_SOCK = "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
  };

  snowfallorg.users.${username}.home.config = {
    programs.git.includes = mkAfter [
      {
        condition = "gitdir/i:~/projects/work/**";
        inherit (config.sops.secrets.gitconfig) path;
      }
    ];
  };

  system.stateVersion = 6;
}
