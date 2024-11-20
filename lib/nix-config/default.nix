{
  mkNixConfig =
    { pkgs, lib }:
    {
      generateNixPathFromInputs = true;
      linkInputs = true;
      distributedBuilds = true;

      extraOptions = ''
        keep-outputs = true
        warn-dirty = false
        keep-derivations = true
      '';

      settings = {
        accept-flake-config = true;
        allowed-users = [ "yash" ];
        auto-optimise-store = false;
        builders-use-substitutes = true;
        experimental-features = lib.mkForce [
          "auto-allocate-uids"
          "ca-derivations"
          "cgroups"
          "flakes"
          "nix-command"
          "recursive-nix"
        ];
        flake-registry = "/etc/nix/registry.json";
        http-connections = 50;
        keep-going = true;
        log-lines = 20;
        max-jobs = "auto";
        sandbox = lib.mkForce (!pkgs.stdenv.isDarwin);
        trusted-users = [
          "root"
          "yash"
        ];
        warn-dirty = false;

        extra-trusted-substituters = [
          "https://cache.garnix.io"
          "https://ai.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://yash-garg.cachix.org"
          "https://cache.nixos.org"
          "https://raspberry-pi-nix.cachix.org"
          "https://cosmic.cachix.org/"
        ];

        extra-trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "yash-garg.cachix.org-1:sHcKOvVej+RlINvt4XVAOE/Cnho3hnrHHRv0uq1u7Xs="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
          "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        ];
      };

      buildMachines = [
        {
          hostName = "vortex";
          maxJobs = 2;
          sshUser = "root";
          system = "aarch64-linux";
          supportedFeatures = [
            "benchmark"
            "big-parallel"
            "kvm"
          ];
        }
      ];
    };
}
