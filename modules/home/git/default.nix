{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.git = enabled // {
    ignores = [
      "key.properties"
      "keystore.properties"
      "*.jks"
      ".direnv/"
      ".DS_Store"
      ".vscode/"
      ".idea/"
      "kls_database.db"
      ".spr.yml"
    ];

    includes = [
      { path = snowfall.fs.get-file ".gitconfig"; }
    ];
  };
}
