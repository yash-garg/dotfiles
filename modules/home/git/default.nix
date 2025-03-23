{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.profiles.${namespace}.git;
in
{
  options.profiles.${namespace}.git = {
    userEmail = mkOption {
      type = types.str;
      default = "me@yashgarg.dev";
      description = "The email address to use for git commits";
    };
  };

  config = {
    programs.git = enabled // {
      ignores = [
        "key.properties"
        "keystore.properties"
        "*.jks"
        ".direnv/"
        ".DS_Store"
        ".vscode/"
        ".idea/"
      ];
      includes = [ { path = snowfall.fs.get-file ".gitconfig"; } ];
      userEmail = lib.mkForce cfg.userEmail;
    };
  };
}
