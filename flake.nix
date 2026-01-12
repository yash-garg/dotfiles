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

        hosts = {
          orion.modules = [
            srvos.nixosModules.mixins-telegraf
            srvos.nixosModules.roles-prometheus
          ];
          vortex.modules = [
            srvos.nixosModules.mixins-telegraf
            srvos.nixosModules.roles-prometheus
          ];
          zenith.modules = [
            srvos.nixosModules.mixins-telegraf
            srvos.nixosModules.roles-prometheus
          ];
        };
      };

      homes.modules = with inputs; [
        nix-index-database.homeModules.nix-index
        spicetify-nix.homeManagerModules.default
      ];

      overlays = with inputs; [
        copyparty.overlays.default
        neovim.overlays.default
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

    darwin.url = "github:LnL7/nix-darwin/master";
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

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    ghostty.url = "github:ghostty-org/ghostty";
    ghostty.inputs.flake-compat.follows = "flake-compat";
    ghostty.inputs.zig.follows = "zig";

    golink.url = "github:tailscale/golink";
    golink.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    neovim.url = "github:yash-garg/neovim";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.inputs.snowfall-lib.follows = "snowfall-lib";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    raspberry-pi-nix.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib.inputs.flake-utils-plus.follows = "flake-utils-plus";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.inputs.flake-utils.follows = "flake-utils";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";
    zig.inputs.flake-compat.follows = "flake-compat";
    zig.inputs.flake-utils.follows = "flake-utils";

    zjstatus.url = "github:dj95/zjstatus";
    zjstatus.inputs.nixpkgs.follows = "nixpkgs";
    zjstatus.inputs.flake-utils.follows = "flake-utils";
  };
}
