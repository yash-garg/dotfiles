{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = {
    name = mkOpt types.str "yash" "The user account.";
    uid = mkOpt (types.nullOr types.int) 502 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      # NOTE: Setting the uid here is required for another
      # module to evaluate successfully since it reads
      # `users.users.${dots.user.name}.uid`.
      uid = mkIf (cfg.uid != null) cfg.uid;
    };

    snowfallorg.users.${config.${namespace}.user.name}.home.config = {
      home = {
        file = {
          ".profile".text = ''
            # The default file limit is far too low and throws an error when rebuilding the system.
            # See the original with: ulimit -Sa
            ulimit -n 4096
          '';
        };
      };
    };

    system.primaryUser = cfg.name;
  };
}
