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
    file = snowfall.fs.get-file "secrets/.gitconfig-work.age";
    mode = "0500";
    owner = username;
  };

  dots = {
    dock.persistentApps = [
      "Linear"
      "Slack"
      "Google Chrome"
      "OrbStack"
      "zoom.us"
    ];

    homebrew.additionalCasks = [
      "linear-linear"
      "slack"
    ];

    user.name = "ygarg";
  };

  snowfallorg.users.${username}.home.config = {
    programs = {
      git.includes = mkAfter [
        { inherit (config.age.secrets.gitconfig) path; }
      ];
      ssh.matchBlocks."github.com".identityFile = mkForce "$HOME/.ssh/git-cf";
    };
  };

  system.stateVersion = 5;
}
