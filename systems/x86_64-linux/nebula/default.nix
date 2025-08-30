{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  sops.secrets.server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";

  dots = {
    server = enabled;

    system.wsl = enabled // {
      hostname = "nebula";
    };

    services = {
      ssh = enabled;

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        setNameservers = false;
        ssh = true;
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;
  topology.self.name = "WSL";

  environment = {
    pathsToLink = [ "/share/zsh" ];
    variables = {
      LANG = "en_US.UTF-8";
    };
  };

  users.users.yash = {
    isNormalUser = true;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    packages = [ pkgs.wget ];
  };

  programs.nix-ld = enabled // {
    package = pkgs.nix-ld-rs;
  };

  system.stateVersion = "24.11";
}
