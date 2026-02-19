{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.lldap;
in
{
  options.${namespace}.services.lldap = {
    enable = mkEnableOption "Enable lldap user directory";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for lldap";
    user = mkOpt types.str "lldap" "The user which lldap will run on";
    group = mkOpt types.str "lldap" "The group of the user which lldap will run on";
    port = mkOpt types.int ports.lldap "The port on which lldap will run";
  };

  config = mkIf cfg.enable {
    sops.secrets.lldap-env = {
      sopsFile = snowfall.fs.get-file "secrets/lldap.env";
      format = "dotenv";
      owner = cfg.user;
      inherit (cfg) group;
      mode = "0600";
    };

    services = {
      lldap = enabled // {
        environmentFile = config.sops.secrets.lldap-env.path;
        silenceForceUserPassResetWarning = true;
        settings = {
          http_port = cfg.port;
          ldap_base_dn = "dc=${concatStringsSep ",dc=" (splitString "." cfg.domain)}";
          ldap_user_email = "alt@${cfg.domain}";
          ldap_user_pass = "$LDAP_USER_PASS";
          database_url = "postgresql://lldap@localhost/lldap?host=/run/postgresql";
        };
      };

    };

    dots.services.caddy.services.users = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
    };

    users.users = mkIf (cfg.user == "lldap") {
      lldap = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "lldap") {
      lldap = { };
    };
  };
}
