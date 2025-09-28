{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
let
  cfg = config.profiles.${namespace}.keychain;
  command = "eval `keychain --eval --agents ssh ${cfg.authKey}`";
in
{
  options.profiles.${namespace}.keychain = {
    enable = mkEnableOption "Enable keychain integration";
    authKey = mkOpt types.str "$HOME/.ssh/git-ssh" "Private ssh key to be added to the ssh-agent";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.keychain ];

    programs = {
      bash.profileExtra = mkIf config.shells.${namespace}.bash.enable command;
      zsh.profileExtra = mkIf config.shells.${namespace}.zsh.enable command;
    };
  };
}
