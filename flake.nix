{
  description = "NixOS and Home Manager Configurations";

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          namespace = "dots";
          meta = {
            name = "yash-nix-configs";
            title = "Yash's Nix configurations";
          };
        };
      };
      treefmtModule = inputs.treefmt-nix.lib.evalModule;
    in
    lib.mkFlake {
      inherit inputs;
      src = ./.;

      channels-config = {
        allowUnfree = true;
        cudaSupport = false;
        permittedInsecurePackages = [ "electron-27.3.11" ];
      };

      deploy = lib.mkDeploy { inherit (inputs) self; };

      systems = with inputs; {
        modules = {
          darwin = [
            nix-index-database.darwinModules.nix-index
            sops-nix.darwinModules.sops
            srvos.darwinModules.desktop
            srvos.darwinModules.mixins-trusted-nix-caches
            stylix.darwinModules.stylix
          ];

          nixos = [
            copyparty.nixosModules.default
            disko.nixosModules.disko
            golink.nixosModules.default
            hister.nixosModules.default
            lanzaboote.nixosModules.lanzaboote
            nix-index-database.nixosModules.nix-index
            nixos-cosmic.nixosModules.default
            nixos-generators.nixosModules.all-formats
            nixos-wsl.nixosModules.default
            sops-nix.nixosModules.sops
            srvos.nixosModules.mixins-trusted-nix-caches
            stylix.nixosModules.stylix
          ];
        };
      };

      homes.modules = with inputs; [
        nix-index-database.homeModules.nix-index
        spicetify-nix.homeManagerModules.default
      ];

      overlays = with inputs; [
        copyparty.overlays.default
        nur.overlays.default
      ];

      outputs-builder = channels: {
        formatter = (treefmtModule channels.nixpkgs ./treefmt.nix).config.build.wrapper;
      };

      templates = {
        cpp.description = "devshell for a C++ project";
        go.description = "devshell for a Golang project";
        node.description = "devshell for a Node.js project";
        rust.description = "devshell for a Rust project";
      };
    }
    // {
      inherit (inputs) self;
    };

  inputs = {
    base16-schemes.url = "github:tinted-theming/schemes";
    base16-schemes.flake = false;

    catppuccin-starship.url = "github:catppuccin/starship";
    catppuccin-starship.flake = false;

    copyparty.url = "github:9001/copyparty";
    copyparty.inputs.nixpkgs.follows = "nixpkgs";
    copyparty.inputs.flake-utils.follows = "flake-utils";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.flake-compat.follows = "flake-compat";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:nix-community/flake-compat";
    flake-compat.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    golink.url = "github:tailscale/golink";
    golink.inputs.nixpkgs.follows = "nixpkgs";
    golink.inputs.systems.follows = "systems";

    hister.url = "github:asciimoo/hister";
    hister.inputs.nixpkgs.follows = "nixpkgs";
    hister.inputs.flake-parts.follows = "flake-parts";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # nixpkgs.url = "github:yash-garg/nixpkgs/nixpkgs-unstable";

    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixos-cosmic.inputs.nixpkgs.follows = "nixpkgs";
    nixos-cosmic.inputs.nixpkgs-stable.follows = "nixpkgs";
    nixos-cosmic.inputs.flake-compat.follows = "flake-compat";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.flake-compat.follows = "flake-compat";

    nur.url = "github:nix-community/NUR";
    nur.inputs.flake-parts.follows = "flake-parts";

    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib.inputs.flake-utils-plus.follows = "flake-utils-plus";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    spicetify-nix.inputs.systems.follows = "systems";

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.systems.follows = "systems";
    stylix.inputs.flake-parts.follows = "flake-parts";

    systems.url = "github:nix-systems/default";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.inputs.flake-utils.follows = "flake-utils";

    zjstatus.url = "github:dj95/zjstatus";
    zjstatus.inputs.nixpkgs.follows = "nixpkgs";
    zjstatus.inputs.flake-utils.follows = "flake-utils";
  };
}
