# lib/autoload/systems.nix
#
# Builds nixosConfigurations/darwinConfigurations from systems/<arch>/<host>,
# auto-pairing each with homes/<arch>/<user>@<host> by folder-name
# convention, PLUS a standalone homeConfigurations."<user>@<host>" for
# every homes/ folder regardless of whether a matching system exists.
# Replaces snowfall-lib's system/home auto-discovery and pairing.
{
  inputs,
  self,
  extraOverlays,
  channelsConfig,
  baseModules,
}:
let
  lib = inputs.nixpkgs.lib;
  root = ../..;
  systemsDir = root + "/systems";
  homesDir = root + "/homes";

  tree = import ./tree.nix { inherit lib; };
  mkExtendedLib = import ./namespace.nix;
  packagesOverlay = import ./packages.nix { };

  overlays = extraOverlays ++ [ packagesOverlay ];

  moduleTree = {
    nixos = tree (root + "/modules/nixos");
    darwin = tree (root + "/modules/darwin");
    home = tree (root + "/modules/home");
  };

  extendedLib = mkExtendedLib { inherit lib; };

  pkgsFor = arch: import inputs.nixpkgs { system = arch; inherit overlays; config = channelsConfig; };

  mkSpecialArgs = username: {
    inherit inputs self;
    namespace = "dots";
    lib = extendedLib;
  }
  // lib.optionalAttrs (username != null) { homeUsername = username; };

  systemArchs = builtins.attrNames (builtins.readDir systemsDir);
  hostsForArch = arch: builtins.attrNames (builtins.readDir (systemsDir + "/${arch}"));
  allSystemHosts = lib.flatten (
    map (arch: map (host: { inherit arch host; }) (hostsForArch arch)) systemArchs
  );

  homeArchs = builtins.attrNames (builtins.readDir homesDir);
  homeDirsForArch = arch: builtins.attrNames (builtins.readDir (homesDir + "/${arch}"));
  allHomeDirs = lib.flatten (
    map (arch: map (homeDirName: { inherit arch homeDirName; }) (homeDirsForArch arch)) homeArchs
  );

  homeDirNameFor =
    arch: host:
    let
      homesArchDir = homesDir + "/${arch}";
      entries = if builtins.pathExists homesArchDir then builtins.readDir homesArchDir else { };
      matches = builtins.filter (name: lib.hasSuffix "@${host}" name) (builtins.attrNames entries);
    in
    if matches == [ ] then null else builtins.head matches;

  mkSystem =
    { arch, host }:
    let
      isDarwin = lib.hasSuffix "-darwin" arch;
      homeDirName = homeDirNameFor arch host;
      username = if homeDirName != null then lib.head (lib.splitString "@" homeDirName) else null;
      specialArgs = mkSpecialArgs username;

      hmModule =
        if isDarwin then
          inputs.home-manager.darwinModules.home-manager
        else
          inputs.home-manager.nixosModules.home-manager;

      systemModule = systemsDir + "/${arch}/${host}/default.nix";
      homeModule = if homeDirName != null then homesDir + "/${arch}/${homeDirName}/default.nix" else null;

      hmUserConfig = lib.optionalAttrs (homeModule != null) {
        home-manager = {
          extraSpecialArgs = specialArgs;
          users.${username} = {
            imports = baseModules.home ++ moduleTree.home ++ [ homeModule ];
          };
        };
      };

      pkgsConfigModule = {
        nixpkgs = {
          inherit overlays;
          config = channelsConfig;
        };
      };

      classBaseModules = if isDarwin then baseModules.darwin else baseModules.nixos;
      classModuleTree = if isDarwin then moduleTree.darwin else moduleTree.nixos;

      mkFn = if isDarwin then inputs.darwin.lib.darwinSystem else lib.nixosSystem;
    in
    mkFn {
      system = arch;
      inherit specialArgs;
      modules = [
        pkgsConfigModule
        hmModule
        systemModule
        hmUserConfig
      ]
      ++ classBaseModules
      ++ classModuleTree;
    };

  mkStandaloneHome =
    { arch, homeDirName }:
    let
      username = lib.head (lib.splitString "@" homeDirName);
      specialArgs = mkSpecialArgs username;
      homeModule = homesDir + "/${arch}/${homeDirName}/default.nix";
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor arch;
      extraSpecialArgs = specialArgs;
      modules = baseModules.home ++ moduleTree.home ++ [ homeModule ];
    };

  builtSystems = map (h: h // { config = mkSystem h; }) allSystemHosts;
  ofClass = isDarwinClass: builtins.filter (h: lib.hasSuffix "-darwin" h.arch == isDarwinClass) builtSystems;
in
{
  nixosConfigurations = builtins.listToAttrs (
    map (h: lib.nameValuePair h.host h.config) (ofClass false)
  );
  darwinConfigurations = builtins.listToAttrs (
    map (h: lib.nameValuePair h.host h.config) (ofClass true)
  );
  homeConfigurations = builtins.listToAttrs (
    map (h: lib.nameValuePair h.homeDirName (mkStandaloneHome h)) allHomeDirs
  );
}
