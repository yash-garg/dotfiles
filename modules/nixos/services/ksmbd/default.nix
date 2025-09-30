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
  cfg = config.${namespace}.services.ksmbd;
  smbToString = x: if builtins.typeOf x == "bool" then lib.boolToString x else toString x;
  shareConfig =
    name:
    let
      share = lib.getAttr name cfg.shares;
    in
    "[${name}]\n "
    + (smbToString (
      map (key: "${key} = ${smbToString (lib.getAttr key share)}\n") (lib.attrNames share)
    ));
in
{
  options.${namespace}.services.ksmbd = with types; {
    enable = mkEnableOption "Enable cifsd kernel server";
    extraConfig = mkOpt lines "" "Additional global section and extra section lines go in here.";
    openFirewall = mkBoolOpt false "Whether to automatically open the necessary ports in the firewall.";
    user = mkOpt str "yash" "User to add to the server";
    passwordFile = mkOpt path null "Path to a file containing password for user";
    securityType = mkOpt str "user" "Samba security type";
    shares = mkOpt (attrsOf (attrsOf unspecified)) { } ''
      A set describing shared resources.
      See <command>man smb.conf</command> for options.
    '';
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "ksmbd" ];

    environment.systemPackages = [ pkgs.ksmbd-tools ];
    environment.etc."ksmbd/ksmbd.conf".text = ''
      [global]
      security = ${cfg.securityType}
      ${cfg.extraConfig}

      ${smbToString (map shareConfig (attrNames cfg.shares))}
    '';

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 445 ];

    services.samba-wsdd = enabled // {
      discovery = true;
      inherit (cfg) openFirewall;
    };

    systemd.services.ksmbd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.ksmbd-tools ];
      preStart = "${pkgs.ksmbd-tools}/bin/ksmbd.adduser -P /run/ksmbd/passwd -a ${cfg.user} < ${cfg.passwordFile}";
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.ksmbd-tools}/bin/ksmbd.mountd -C /etc/ksmbd/ksmbd.conf -P /run/ksmbd/passwd";
        Restart = "always";
        PrivateTmp = true;
        RuntimeDirectory = "ksmbd";
      };
    };
  };
}
