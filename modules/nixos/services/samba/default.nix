{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.samba;
  bool-to-yes-no = value: if value then "yes" else "no";

  shares-submodule =
    with types;
    submodule (
      { name, ... }:
      {
        options = {
          path = mkOpt str null "The path to serve.";
          public = mkBoolOpt false "Whether the share is public.";
          browseable = mkBoolOpt true "Whether the share is browseable.";
          comment = mkOpt str name "An optional comment.";
          read-only = mkBoolOpt false "Whether the share should be read only.";
          only-owner-editable = mkBoolOpt false "Whether the share is only writable by the system owner (plusultra.user.name).";

          extra-config = mkOpt attrs { } "Extra configuration options for the share.";
        };
      }
    );
in
{
  options.${namespace}.services.samba = {
    enable = mkEnableOption "Samba";
    workgroup = mkOpt types.str "WORKGROUP" "The workgroup to use.";
    browseable = mkBoolOpt true "Whether the shares are browseable.";

    shares = mkOpt (types.attrsOf shares-submodule) { } "The shares to serve.";
  };

  config = mkIf cfg.enable {
    services.samba = enabled // {
      openFirewall = true;

      settings = mapAttrs (
        _name: value:
        {
          inherit (value) path comment;

          public = bool-to-yes-no value.public;
          browseable = bool-to-yes-no value.browseable;
          "read only" = bool-to-yes-no value.read-only;
        }
        // (optionalAttrs value.only-owner-editable {
          "write list" = config.${namespace}.user.name;
          "read list" = "guest, nobody";
          "create mask" = "0755";
        })
        // value.extra-config
      ) cfg.shares;
    };

    # Advertise shares to Windows hosts
    services.samba-wsdd = enabled // {
      discovery = true;
      openFirewall = true;
      workgroup = "WORKGROUP";
    };
  };
}
