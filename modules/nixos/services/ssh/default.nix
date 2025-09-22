{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ssh;
  bool-to-yes-no = value: if value then "yes" else "no";
in
{
  options.${namespace}.services.ssh = {
    enable = mkEnableOption "Setup SSH";

    keys = mkOption {
      type = types.listOf types.str;
      default = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx1G6WZ4MQ8c4hUZy2Be+GF5fZQJSssn4qnJoQ4MPxz" ];
      description = "List of SSH keys to add to the authorized_keys file";
    };

    addRootKeys = mkBoolOpt false "Add the same keys to the root user";

    package = mkPackageOption pkgs "openssh" { };

    passwordAuth = mkBoolOpt true "Allow password authentication";

    permitRootLogin = mkBoolOpt false "Allow root login";
  };

  config = mkIf cfg.enable {
    services.openssh = enabled // {
      inherit (cfg) package;
      settings = {
        X11Forwarding = mkDefault true;
        PermitRootLogin = mkForce (bool-to-yes-no cfg.permitRootLogin);
        PasswordAuthentication = mkDefault cfg.passwordAuth;
      };
      openFirewall = true;
    };

    users.users.yash.openssh.authorizedKeys.keys = cfg.keys;
    users.users.root.openssh.authorizedKeys.keys = mkIf cfg.addRootKeys cfg.keys;
  };
}
