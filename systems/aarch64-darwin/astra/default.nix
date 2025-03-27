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
  age.secrets.gitconfig = {
    file = snowfall.fs.get-file "secrets/.gitconfig-freelance.age";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Firefox"
      "Google Chrome"
      "OrbStack"
    ];

    homebrew = {
      additionalCasks = [
        "chromedriver"
        "firefox@beta"
        "google-chrome"
        "notion-calendar"
      ];

      masApps = {
        Amphetamine = 937984704;
        Bitwarden = 1352778147;
      };
    };
  };

  environment.variables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  snowfallorg.users.${username}.home.config = {
    programs.git.includes = mkAfter [
      { inherit (config.age.secrets.gitconfig) path; }
    ];
  };

  system.stateVersion = 5;
}
