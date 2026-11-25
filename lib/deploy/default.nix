{ inputs }:
let
  inherit (inputs) deploy-rs;
in
{
  mkDeploy =
    { self }:
    let
      hosts = inputs.nixpkgs.lib.filterAttrs (_: machine: machine.config.services.openssh.enable) (
        self.nixosConfigurations or { }
      );
      nodes = builtins.mapAttrs (_: machine: {
        hostname = machine.config.networking.hostName;
        fastConnection = true;
        remoteBuild = false;
        autoRollback = false;
        magicRollback = false;
        profiles.system = {
          user = "root";
          sshUser = "yash";
          path = deploy-rs.lib.${machine.pkgs.system}.activate.nixos machine;
        };
      }) hosts;
    in
    {
      inherit nodes;
    };
}
