{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  documentation = enabled // {
    doc = disabled;
    man = enabled;
    dev = disabled;
  };

  programs.nh = enabled // {
    clean.enable = config.${namespace}.server.enable;
    flake = "$HOME/dotfiles";
  };

  users.users.yash.packages = with pkgs; [ nix-output-monitor ];

  nix =
    lib.recursiveUpdate
      (mkNixConfig {
        inherit lib pkgs;
      })
      {
        optimise.automatic = true;
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
        settings = {
          min-free = toString (5 * 1024 * 1024 * 1024); # 5 GiB
          max-free = toString (10 * 1024 * 1024 * 1024); # 10 GiB
        };
      };

  services.journald.settings.Journal = {
    SystemMaxUse = "512M";
    RuntimeMaxUse = "128M";
  };
}
