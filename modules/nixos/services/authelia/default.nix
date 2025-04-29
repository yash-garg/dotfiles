{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.authelia;
in
{
  options.${namespace}.services.authelia = {
    enable = mkEnableOption "Enable Authelia OIDC";
  };

  config = mkIf cfg.enable {
    age.secrets =
      let
        hostPath = "zenith/authelia";
      in
      {
        jwtSecret.file = getSecret "jwt" hostPath;
        sessionSecret.file = getSecret "session" hostPath;
        storageEncryptionKey.file = getSecret "storage" hostPath;
      };

    services.authelia = {
      instances.main = enabled // {
        secrets = {
          jwtSecretFile = config.age.secrets.jwtSecret.path;
          sessionSecretFile = config.age.secrets.sessionSecret.path;
          storageEncryptionKeyFile = config.age.secrets.storageEncryptionKey.path;
        };
        settings = builtins.readFile ./config.yml;
      };
    };
  };
}
