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
    includes = mkOption {
      default = [ ];
      type = types.listOf types.path;
      description = ''
        A list of files to include in the git configuration.
      '';
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
      includes = [ { path = snowfall.fs.get-file ".gitconfig"; } ] ++ cfg.includes;
      userEmail = lib.mkForce cfg.userEmail;
    };
  };
}
