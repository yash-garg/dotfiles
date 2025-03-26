{
  description = "NixOS and Home Manager Configurations";

  outputs =
    inputs:
    let
      commonModules = with inputs; [
        agenix.nixosModules.default
        nix-topology.nixosModules.default
      ];
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

      systems.modules.darwin =
        with inputs;
        [
          nix-index-database.darwinModules.nix-index
          srvos.darwinModules.mixins-trusted-nix-caches
          stylix.darwinModules.stylix
        ]
        ++ commonModules;

      systems.modules.nixos =
        with inputs;
        [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          nix-index-database.nixosModules.nix-index
          nixos-cosmic.nixosModules.default
          nixos-generators.nixosModules.all-formats
          nixos-wsl.nixosModules.default
          srvos.nixosModules.mixins-trusted-nix-caches
          stylix.nixosModules.stylix
        ]
        ++ commonModules;

      systems.hosts.cosmos.modules = with inputs; [
        raspberry-pi-nix.nixosModules.raspberry-pi
        srvos.nixosModules.mixins-mdns
        vscode-server.nixosModules.default
      ];

      systems.hosts.nova.modules = with inputs; [
        srvos.nixosModules.desktop
        srvos.nixosModules.mixins-systemd-boot
      ];

      systems.hosts = {
        aurora.modules = with inputs; [ srvos.darwinModules.desktop ];
        trinity.modules = with inputs; [ srvos.darwinModules.desktop ];
      };

      homes.modules = with inputs; [
        nix-index-database.hmModules.nix-index
        spicetify-nix.homeManagerModules.default
      ];

      overlays = with inputs; [
        neovim.overlays.default
        nix-topology.overlays.default
        nixpkgs-wayland.overlay
        nur.overlays.default
      ];

      outputs-builder = channels: {
        formatter = (treefmtModule channels.nixpkgs ./treefmt.nix).config.build.wrapper;

        packages = {
          # minimal-iso = inputs.self.install-isoConfigurations.minimal;
        };

        topology = import inputs.nix-topology {
          pkgs = channels.nixpkgs;
          modules = [
            { inherit (inputs.self) nixosConfigurations; }
            ./topology
          ];
        };
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
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    base16-schemes.url = "github:tinted-theming/schemes";
    base16-schemes.flake = false;

    catppuccin-starship.url = "github:catppuccin/starship";
    catppuccin-starship.flake = false;

    darwin.url = "github:LnL7/nix-darwin";
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
    ghostty.inputs.nixpkgs-stable.follows = "nixpkgs";
    ghostty.inputs.nixpkgs-unstable.follows = "nixpkgs";
    ghostty.inputs.flake-compat.follows = "flake-compat";
    ghostty.inputs.zig.follows = "zig";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    lix.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
    lix.inputs.nixpkgs.follows = "nixpkgs";

    neovim.url = "github:yash-garg/neovim";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.inputs.snowfall-lib.follows = "snowfall-lib";

    nh_darwin.url = "github:ToyVo/nh_darwin";
    nh_darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
    nix-topology.inputs.devshell.follows = "devshell";
    nix-topology.inputs.flake-utils.follows = "flake-utils";

    nixified-ai.url = "github:nixified-ai/flake";
    nixified-ai.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.flake-compat.follows = "flake-compat";

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

    paisa.url = "github:ananthakumaran/paisa";
    paisa.inputs.nixpkgs.follows = "nixpkgs";
    paisa.inputs.flake-utils.follows = "flake-utils";

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    raspberry-pi-nix.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib.inputs.flake-utils-plus.follows = "flake-utils-plus";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix/f121a142abde1b6aa9738e4c21a330c0ddd4eb70";
    stylix.inputs.flake-compat.follows = "flake-compat";
    stylix.inputs.home-manager.follows = "home-manager";
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
