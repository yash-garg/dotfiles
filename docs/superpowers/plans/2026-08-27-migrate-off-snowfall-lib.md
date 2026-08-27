# Migrate off snowfall-lib Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the unmaintained `snowfall-lib` flake input, replacing its auto-discovery, namespace-plumbing, and flake-assembly behavior with a small local `lib/autoload/` library, with zero behavior change across all outputs: 4 `nixosConfigurations`, 2 `darwinConfigurations`, and 8 `homeConfigurations` (including the 2 standalone-only homes, `yash@apollo` and `yash@ares`, which have no matching `systems/` entry).

**Architecture:** Four small, independently-readable Nix functions under `lib/autoload/` (`tree.nix`, `namespace.nix`, `packages.nix`, `overlays.nix`, `systems.nix`) replace `snowfall-lib.mkLib`/`mkFlake`. `flake.nix` is rewritten to call them directly. ~50 call sites across existing modules get mechanical renames (`snowfallorg.users.*` → `home-manager.users.*`, `snowfall.fs.get-file` → `lib.dots.get-file`).

**Tech Stack:** Nix flakes, nixpkgs, nix-darwin, home-manager, sops-nix, deploy-rs.

**Spec:** `docs/superpowers/specs/2026-08-27-migrate-off-snowfall-lib-design.md`

## Global Constraints

- Zero behavior change: every host must build to an equivalent config before and after.
- The `dots` namespace convention (`namespace = "dots"`, `with lib.${namespace};`, `config.${namespace}.*`) must keep working with **no edits** to the 129+135 existing call sites that use it.
- New hosts/homes still require only a folder (no `flake.nix` edit). New modules/overlays still require only a `default.nix` file (no import-list edit).
- Single PR — all tasks land together, validated as a whole before merge.
- No `flake-parts` or other framework introduced as a replacement.

---

## Task 0: Capture baseline for later comparison

**Files:**
- Create: `/tmp/snowfall-migration-baseline.json` (scratch, not committed)

**Interfaces:**
- Produces: baseline file used by Task 11's diff.

- [ ] **Step 1: Capture current flake outputs**

`nix flake show --json` currently errors out entirely on this repo (snowfall-lib's `flake-utils-plus` dependency evaluates `x86_64-darwin`, which nixpkgs-unstable has dropped) — use targeted `nix eval` instead, same as the `justfile`'s `eval` recipe:

```bash
cd /Users/yash/dotfiles
nix eval .#nixosConfigurations --apply builtins.attrNames --json | tee /tmp/snowfall-migration-baseline-nixos.json
nix eval .#darwinConfigurations --apply builtins.attrNames --json | tee /tmp/snowfall-migration-baseline-darwin.json
nix eval .#homeConfigurations --apply builtins.attrNames --json | tee /tmp/snowfall-migration-baseline-home.json
```

Expected:
- nixosConfigurations: `["orion","quasar","vortex","zenith"]`
- darwinConfigurations: `["astra","aurora"]`
- homeConfigurations: `["yash@apollo","yash@ares","yash@astra","yash@orion","yash@quasar","yash@vortex","yash@zenith","ygarg@aurora"]`

- [ ] **Step 2: Record it in a scratch note**

Save the two host lists somewhere you'll paste back in Task 11 (a comment in your terminal scrollback is fine — this file is not committed).

No commit for this task (nothing changes in the repo).

---

## Task 1: `lib/autoload/tree.nix` — recursive `default.nix` finder

**Files:**
- Create: `lib/autoload/tree.nix`

**Interfaces:**
- Produces: `{ lib }: dir: [ path ]` — a function taking the extended `lib` (only `lib.flatten`/`lib.mapAttrsToList` are used, plain `nixpkgs.lib` is fine), then a directory path, returning a list of paths to every `default.nix` found in `dir` at any depth (not counting a `default.nix` directly at `dir`'s root, matching how `modules/nixos/default.nix` doesn't exist today and shouldn't be picked up as "itself").

- [ ] **Step 1: Write the file**

```nix
# lib/autoload/tree.nix
#
# Recursively find every `default.nix` file under `dir`, at any depth,
# and return them as a list of paths. Used to auto-import modules and
# overlays by folder convention, replacing snowfall-lib's module
# auto-discovery.
{ lib }:
dir:
let
  walk =
    relPath:
    let
      full = if relPath == "" then dir else dir + "/${relPath}";
      entries = builtins.readDir full;
      collect =
        name: type:
        let
          path = if relPath == "" then name else "${relPath}/${name}";
        in
        if type == "directory" then
          walk path
        else if name == "default.nix" && relPath != "" then
          [ (dir + "/${path}") ]
        else
          [ ];
    in
    lib.flatten (lib.mapAttrsToList collect entries);
in
walk ""
```

- [ ] **Step 2: Smoke-test it against the real repo**

Run:
```bash
cd /Users/yash/dotfiles
nix eval --impure --expr '
  let
    lib = (import <nixpkgs> {}).lib;
    tree = import ./lib/autoload/tree.nix { inherit lib; };
  in {
    home = builtins.length (tree ./modules/home);
    nixos = builtins.length (tree ./modules/nixos);
    darwin = builtins.length (tree ./modules/darwin);
  }
'
```

Expected: `{ darwin = 11; home = 42; nixos = 76; }` — matching the current `fd default.nix modules/{home,nixos,darwin} -t f | wc -l` counts. If the numbers don't match, re-check for `.direnv`/`result` symlinks under `modules/` that shouldn't be walked (there shouldn't be any, but confirm with `fd default.nix modules -t f | wc -l` = 129 total).

- [ ] **Step 3: Commit**

```bash
git add lib/autoload/tree.nix
git commit -m "feat: add recursive default.nix finder for module/overlay auto-import"
```

---

## Task 2: `lib/autoload/namespace.nix` — extend `lib`/`pkgs` with the `dots` namespace

**Files:**
- Create: `lib/autoload/namespace.nix`

**Interfaces:**
- Consumes: nothing external (imports `../module`, `../ports`, `../trusted-proxies`, `../nix-config` directly).
- Produces: `{ lib }: <extended lib>` — takes plain `nixpkgs.lib`, returns `lib.extend`-wrapped lib where `lib.dots` = the flattened merge of `lib/module`, `lib/ports`, `lib/trusted-proxies`, `lib/nix-config`, plus `lib.dots.get-file`. This replicates snowfall's behavior of merging every `lib/<name>/default.nix` file's top-level keys into `lib.${namespace}` (confirmed by current usage: `ports.wireguard`, `trustedProxies.list`, `mkNixConfig { ... }` are all called bare via `with lib.${namespace};`).

- [ ] **Step 1: Write the file**

```nix
# lib/autoload/namespace.nix
#
# Extends `lib` with `lib.dots`, replicating snowfall-lib's namespace
# merging: every `lib/<name>/default.nix` file's top-level attrs are
# flattened together under `lib.dots`, plus a `get-file` helper that
# replaces `snowfall.fs.get-file`.
{ lib }:
let
  root = ../..;

  custom = lib.foldl' lib.recursiveUpdate { } [
    (import ../module { inherit lib; })
    (import ../ports { })
    (import ../trusted-proxies { })
    (import ../nix-config { })
  ];
in
lib.extend (
  final: _prev: {
    dots = custom // {
      get-file = relPath: root + "/${relPath}";
    };
  }
)
```

- [ ] **Step 2: Verify each merged `lib/*` file's actual signature**

Run:
```bash
cd /Users/yash/dotfiles
head -3 lib/module/default.nix lib/ports/default.nix lib/trusted-proxies/default.nix lib/nix-config/default.nix
```

Expected: `lib/module/default.nix` takes `{ lib, ... }:`, `lib/ports/default.nix` and `lib/trusted-proxies/default.nix` take no useful args (plain attrsets, confirm they don't error when called with `{ }`), `lib/nix-config/default.nix` takes `{ pkgs, lib }:` (note: `mkNixConfig` itself takes `{ pkgs, lib }` as its *returned function's* argument, not `lib/nix-config/default.nix` itself — re-read the file: it's `{ mkNixConfig = { pkgs, lib }: { ... }; }`, i.e. the outer file takes no args). Adjust the `import ../nix-config { }` call above if this doesn't match — it should, since `lib/nix-config/default.nix` starts with `{ mkNixConfig = ...`, not a function.

- [ ] **Step 3: Smoke-test the merge**

Run:
```bash
cd /Users/yash/dotfiles
nix eval --impure --expr '
  let
    lib = (import <nixpkgs> {}).lib;
    extended = import ./lib/autoload/namespace.nix { inherit lib; };
  in {
    hasMkOpt = extended.dots ? mkOpt;
    hasEnabled = extended.dots ? enabled;
    wireguardPort = extended.dots.ports.wireguard;
    hasTrustedProxies = extended.dots ? trustedProxies;
    hasMkNixConfig = extended.dots ? mkNixConfig;
    getFileWorks = builtins.toString (extended.dots.get-file "flake.nix");
  }
'
```

Expected: `hasMkOpt = true; hasEnabled = true; wireguardPort = 51820; hasTrustedProxies = true; hasMkNixConfig = true;` and `getFileWorks` ending in `/flake.nix`.

- [ ] **Step 4: Commit**

```bash
git add lib/autoload/namespace.nix
git commit -m "feat: add lib.dots namespace extension replacing snowfall-lib namespace merging"
```

---

## Task 3: `lib/autoload/packages.nix` — `packages/*` as an overlay

**Files:**
- Create: `lib/autoload/packages.nix`

**Interfaces:**
- Produces: `{ }: final: prev: { dots = { <name> = <derivation>; ... }; }` — a standard nixpkgs overlay function exposing every top-level directory under `packages/` as `pkgs.dots.<name>`, replacing `pkgs.${namespace}.git-spr` etc.

- [ ] **Step 1: Write the file**

```nix
# lib/autoload/packages.nix
#
# Exposes every top-level directory under `packages/` as `pkgs.dots.<name>`,
# replacing snowfall-lib's package auto-discovery.
_: final: prev:
let
  root = ../../packages;
  entries = builtins.readDir root;
  names = builtins.filter (name: (entries.${name}) == "directory") (builtins.attrNames entries);
in
{
  dots = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = final.callPackage (root + "/${name}") { };
    }) names
  );
}
```

- [ ] **Step 2: Verify it matches `default.nix`'s manual list**

Run:
```bash
cd /Users/yash/dotfiles
fd . packages -t d -d 1
```

Expected: `git-spr`, `monolisa-nerdfonts`, `mpv-scripts` — matching the three packages currently listed by hand in the root `default.nix`. `packages/README.md` is a file, not a directory, so it's correctly excluded by the `type == "directory"` filter.

- [ ] **Step 3: Smoke-test the overlay shape (without building)**

Run:
```bash
cd /Users/yash/dotfiles
nix eval --impure --expr '
  let
    pkgs = import <nixpkgs> { overlays = [ (import ./lib/autoload/packages.nix { }) ]; };
  in builtins.attrNames pkgs.dots
'
```

Expected: `[ "git-spr" "monolisa-nerdfonts" "mpv-scripts" ]`.

- [ ] **Step 4: Commit**

```bash
git add lib/autoload/packages.nix
git commit -m "feat: add packages/* auto-discovery overlay"
```

---

## Task 4: `lib/autoload/overlays.nix` — `overlays/*` auto-discovery

**Files:**
- Create: `lib/autoload/overlays.nix`

**Interfaces:**
- Consumes: `lib/autoload/tree.nix` (`{ lib }: dir: [ path ]`).
- Produces: `{ lib, inputs }: [ overlayFn ]` — a list of standard `final: prev: {...}` overlay functions, built from every `overlays/*/default.nix` (each of which currently has the shape `inputs: final: prev: {...}`, confirmed in `overlays/{slack,spicetify,vesktop,zjstatus}/default.nix`).

- [ ] **Step 1: Write the file**

```nix
# lib/autoload/overlays.nix
#
# Collects every `overlays/*/default.nix` (each shaped as
# `inputs: final: prev: {...}`) and applies `inputs`, producing a plain
# list of `final: prev: {...}` overlays. Replaces snowfall-lib's
# overlay auto-discovery.
{ lib, inputs }:
let
  tree = import ./tree.nix { inherit lib; };
  files = tree ../../overlays;
in
map (file: (import file) inputs) files
```

- [ ] **Step 2: Smoke-test the file count**

Run:
```bash
cd /Users/yash/dotfiles
nix eval --impure --expr '
  let
    lib = (import <nixpkgs> {}).lib;
  in builtins.length (import ./lib/autoload/tree.nix { inherit lib; } ./overlays)
'
```

Expected: `4` (slack, spicetify, vesktop, zjstatus).

- [ ] **Step 3: Commit**

```bash
git add lib/autoload/overlays.nix
git commit -m "feat: add overlays/* auto-discovery"
```

---

## Task 5: `lib/autoload/systems.nix` — build `nixosConfigurations`/`darwinConfigurations`/`homeConfigurations`

**Files:**
- Create: `lib/autoload/systems.nix`

**Interfaces:**
- Consumes: `lib/autoload/tree.nix`, `lib/autoload/namespace.nix`, `lib/autoload/packages.nix`.
- Produces: `{ inputs, self, extraOverlays, channelsConfig, baseModules }: { nixosConfigurations = {...}; darwinConfigurations = {...}; homeConfigurations = {...}; }`
  - `baseModules :: { nixos = [module]; darwin = [module]; home = [module]; }` — the cross-cutting third-party modules (currently `systems.modules.darwin`/`.nixos` and `homes.modules` in `flake.nix`).
  - Each built system's `specialArgs` includes: `inputs`, `self`, `namespace = "dots"`, `lib` (extended via `namespace.nix`), and `homeUsername` (the username derived from the matching `homes/` folder, when one exists) — consumed by Task 9's rewrite of `modules/home/user/default.nix`.
  - **Every** `homes/<arch>/<user>@<host>/default.nix` folder (8 total) produces a standalone `homeConfigurations."<user>@<host>"` output via `home-manager.lib.homeManagerConfiguration`, independent of whether a matching `systems/` entry exists — this is required for `yash@apollo` and `yash@ares` (`x86_64-linux`), which have no matching `systems/` folder at all and are standalone home-manager-only machines. Confirmed via `nix eval .#homeConfigurations --apply builtins.attrNames --json` against the current (pre-migration) flake: `["yash@apollo","yash@ares","yash@astra","yash@orion","yash@quasar","yash@vortex","yash@zenith","ygarg@aurora"]`.

- [ ] **Step 1: Write the file**

```nix
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
```

- [ ] **Step 2: Syntax-check the file**

Run:
```bash
cd /Users/yash/dotfiles
nix-instantiate --parse lib/autoload/systems.nix > /dev/null && echo OK
```

Expected: `OK`. Full functional testing happens in Task 6 once `flake.nix` wires this in (it needs real `inputs`, which only exist inside the flake).

- [ ] **Step 3: Commit**

```bash
git add lib/autoload/systems.nix
git commit -m "feat: add systems.nix host/home auto-discovery and wiring"
```

---

## Task 6: Rewrite `flake.nix`

**Files:**
- Modify: `flake.nix`

**Interfaces:**
- Consumes: `lib/autoload/systems.nix`, `lib/autoload/overlays.nix`, `lib/deploy` (unchanged), `treefmt-nix` (unchanged).
- Produces: flake outputs `nixosConfigurations`, `darwinConfigurations`, `deploy`, `checks`, `templates`, `formatter`, `packages`, `overlays.default` — same shape as before.

- [ ] **Step 1: Replace the `outputs` function**

```nix
{
  description = "NixOS and Home Manager Configurations";

  outputs =
    inputs:
    let
      inherit (inputs) self;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      extraOverlays = with inputs; [
        copyparty.overlays.default
        nur.overlays.default
      ]
      ++ (import ./lib/autoload/overlays.nix { inherit inputs; lib = inputs.nixpkgs.lib; });

      channelsConfig = {
        allowUnfree = true;
        cudaSupport = false;
        permittedInsecurePackages = [ "electron-27.3.11" ];
      };

      baseModules = with inputs; {
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

        home = [
          nix-index-database.homeModules.nix-index
          spicetify-nix.homeManagerModules.default
        ];
      };

      systemsOutputs = import ./lib/autoload/systems.nix {
        inherit inputs self extraOverlays channelsConfig baseModules;
      };

      deployLib = import ./lib/deploy { inherit inputs; };

      packagesOverlay = import ./lib/autoload/packages.nix { };

      pkgsFor = system: import inputs.nixpkgs {
        inherit system;
        overlays = extraOverlays ++ [ packagesOverlay ];
        config = channelsConfig;
      };
      forAllSystems = f: inputs.nixpkgs.lib.genAttrs supportedSystems (system: f system (pkgsFor system));
    in
    {
      inherit (systemsOutputs) nixosConfigurations darwinConfigurations homeConfigurations;

      deploy = deployLib.mkDeploy { inherit self; };

      checks = forAllSystems (
        system: _pkgs:
        builtins.mapAttrs (_: deployChecksLib: deployChecksLib.deployChecks self.deploy) inputs.deploy-rs.lib.${system} or { }
      );

      formatter = forAllSystems (
        _system: pkgs: (inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper
      );

      packages = forAllSystems (_system: pkgs: pkgs.dots or { });

      overlays.default = packagesOverlay;

      templates = {
        cpp.description = "devshell for a C++ project";
        cpp.path = ./templates/cpp;
        go.description = "devshell for a Golang project";
        go.path = ./templates/go;
        node.description = "devshell for a Node.js project";
        node.path = ./templates/node;
        rust.description = "devshell for a Rust project";
        rust.path = ./templates/rust;
      };
    };

  inputs = {
```

**Note on `checks`:** the code above reuses `checks/deploy/default.nix` as-is (unchanged file, already returns an attrset keyed by system via `deploy-rs.lib.${system}`) rather than duplicating its `deployChecks` logic inline — the `checks = let allChecks = import ./checks/deploy { inherit inputs; }; in ...` block in Step 1 is the final, only version to implement. Do not implement any other variant.

- [ ] **Step 2: Remove `snowfall-lib` and `flake-utils-plus` input declarations**

Delete these lines from the `inputs` block:
```nix
    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib.inputs.flake-utils-plus.follows = "flake-utils-plus";
```
and (since it was only pulled in for `snowfall-lib`):
```nix
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";
```

First confirm nothing else references `flake-utils-plus`:
```bash
cd /Users/yash/dotfiles
grep -rn "flake-utils-plus" --include="*.nix" .
```
Expected after this edit: no matches outside of what you're about to delete.

- [ ] **Step 3: Parse-check `flake.nix`**

Run:
```bash
cd /Users/yash/dotfiles
nix-instantiate --parse flake.nix > /dev/null && echo OK
```

Expected: `OK`. Full evaluation will still fail at this point — Tasks 7-9's mechanical replacements haven't happened yet, so modules still reference `snowfallorg.*`/`snowfall.fs.*`, which no longer exist. That's expected; don't try to `nix flake check` yet.

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "feat: rewrite flake.nix to use lib/autoload instead of snowfall-lib"
```

---

## Task 7: Replace `snowfallorg.users.<user>.home.config` with `home-manager.users.<user>`

**Files:**
- Modify: `systems/aarch64-darwin/astra/default.nix`
- Modify: `systems/aarch64-darwin/aurora/default.nix`
- Modify: `modules/nixos/desktop/android-dev/default.nix`
- Modify: `modules/nixos/desktop/gnome/default.nix`
- Modify: `modules/nixos/desktop/stylix/default.nix`
- Modify: `modules/darwin/homebrew/default.nix`
- Modify: `modules/darwin/user/default.nix`

**Interfaces:**
- Consumes: `home-manager.users.<name>` — a standard option provided by `home-manager.{nixosModules,darwinModules}.home-manager`, now included in every system's `modules` list via Task 5's `hmModule`.

- [ ] **Step 1: Confirm the exact call sites**

Run:
```bash
cd /Users/yash/dotfiles
grep -rn "snowfallorg\.users\." --include="*.nix" .
```

Expected: exactly the 7 lines listed above (one per file), each of the form `snowfallorg.users.<expr>.home.config = {`.

- [ ] **Step 2: Apply the rename**

Run:
```bash
cd /Users/yash/dotfiles
grep -rl "snowfallorg\.users\." --include="*.nix" . | xargs sed -i '' -E 's/snowfallorg\.users\.([^ ]+)\.home\.config = \{/home-manager.users.\1 = {/'
```

(On Linux, drop the empty `''` after `-i`.)

- [ ] **Step 3: Verify the rename**

Run:
```bash
cd /Users/yash/dotfiles
grep -rn "snowfallorg" --include="*.nix" .
```

Expected: only `modules/home/user/default.nix` still matches (`config.snowfallorg.user.name` / `.home.directory`) — that's handled separately in Task 9.

Also confirm each edited line now reads correctly:
```bash
grep -rn "home-manager\.users\." --include="*.nix" systems/aarch64-darwin modules/nixos/desktop modules/darwin
```

Expected: 7 matches, one per file from Step 1.

- [ ] **Step 4: Commit**

```bash
git add systems/aarch64-darwin modules/nixos/desktop modules/darwin
git commit -m "refactor: replace snowfallorg.users.*.home.config with home-manager.users.*"
```

---

## Task 8: Replace `snowfall.fs.get-file` / `lib.snowfall.fs.get-file` with `lib.dots.get-file`

**Files:**
- Modify: 24 files under `systems/`, `modules/home/{env,git}`, `modules/nixos/services/**`, `modules/darwin/homebrew` (full list produced by Step 1 below).

**Interfaces:**
- Consumes: `lib.dots.get-file` from Task 2, available in every module via the `lib` special-arg set by Task 5.

- [ ] **Step 1: List every call site to be changed**

Run:
```bash
cd /Users/yash/dotfiles
grep -rln "snowfall\.fs\." --include="*.nix" .
```

Expected: the same file list identified during the design phase (23 `modules/nixos/services/*` + `modules/nixos/services/sso-auth/**`, `modules/home/env`, `modules/home/git`, `modules/darwin/homebrew`, `systems/aarch64-darwin/{astra,aurora}`, `systems/{x86_64-linux/quasar,aarch64-linux/vortex,aarch64-linux/zenith}`).

- [ ] **Step 2: Apply the rename (longest pattern first to avoid double-prefixing)**

Run:
```bash
cd /Users/yash/dotfiles
files=$(grep -rl "snowfall\.fs\." --include="*.nix" .)

# 1. The one-off "get-snowfall-file" call (modules/darwin/homebrew)
sed -i '' -E 's/lib\.snowfall\.fs\.get-snowfall-file "modules\/home"/lib.dots.get-file "modules\/home"/' modules/darwin/homebrew/default.nix

# 2. Explicit `lib.snowfall.fs.get-file` call sites
echo "$files" | xargs sed -i '' -E 's/lib\.snowfall\.fs\.get-file/lib.dots.get-file/g'

# 3. Remaining bare `snowfall.fs.get-file` call sites
echo "$files" | xargs sed -i '' -E 's/snowfall\.fs\.get-file/lib.dots.get-file/g'
```

(Drop the empty `''` after `-i` on Linux.)

- [ ] **Step 3: Verify no `snowfall` references remain**

Run:
```bash
cd /Users/yash/dotfiles
grep -rn "snowfall" --include="*.nix" . | grep -v "lib/autoload\|lib/module\|lib/ports\|lib/trusted-proxies\|lib/nix-config"
```

Expected: no output (all `snowfall.*` call sites replaced). If `modules/home/user/default.nix` still shows `config.snowfallorg.user.*`, that's expected — fixed in Task 9.

- [ ] **Step 4: Confirm every changed file has `lib` in its module arguments**

Since `lib.dots.get-file` requires `lib` to be a bound name, check each changed file's function head includes `lib`:

```bash
cd /Users/yash/dotfiles
for f in $(echo "$files"); do
  head -8 "$f" | grep -q '\blib\b' || echo "MISSING lib arg: $f"
done
```

Expected: no output. If any file is flagged, add `lib` to its top-level function argument attrset (e.g. `{ lib, ... }:`).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: replace snowfall.fs.get-file with lib.dots.get-file"
```

---

## Task 9: Rewrite `modules/home/user/default.nix`

**Files:**
- Modify: `modules/home/user/default.nix`

**Interfaces:**
- Consumes: `homeUsername` — the special-arg produced by Task 5's `mkSystem` (the username parsed from the matching `homes/<arch>/<user>@<host>` folder).

- [ ] **Step 1: Rewrite the file**

```nix
# modules/home/user/default.nix
{ pkgs, homeUsername, ... }:
{
  home = {
    username = homeUsername;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${homeUsername}" else "/home/${homeUsername}";
  };
}
```

- [ ] **Step 2: Syntax-check**

Run:
```bash
cd /Users/yash/dotfiles
nix-instantiate --parse modules/home/user/default.nix > /dev/null && echo OK
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add modules/home/user/default.nix
git commit -m "refactor: replace snowfallorg.user.* with homeUsername special-arg"
```

---

## Task 10: Remove `snowfall-lib` from the lock file

**Files:**
- Modify: `flake.lock`

**Interfaces:** none (generated file).

- [ ] **Step 1: Regenerate the lock file**

Run:
```bash
cd /Users/yash/dotfiles
nix flake lock
```

- [ ] **Step 2: Confirm `snowfall-lib` and `flake-utils-plus` are gone**

Run:
```bash
cd /Users/yash/dotfiles
grep -n "snowfall-lib\|flake-utils-plus" flake.lock
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add flake.lock
git commit -m "chore: drop snowfall-lib and flake-utils-plus from flake.lock"
```

---

## Task 11: Full validation across all outputs

**Files:** none (validation only).

**Interfaces:** none.

- [ ] **Step 1: `nix flake check`**

Run:
```bash
cd /Users/yash/dotfiles
nix flake check
```

Expected: passes with no errors.

- [ ] **Step 2: Compare output key lists against the Task 0 baseline**

Run:
```bash
cd /Users/yash/dotfiles
nix eval .#nixosConfigurations --apply builtins.attrNames --json > /tmp/snowfall-migration-after-nixos.json
nix eval .#darwinConfigurations --apply builtins.attrNames --json > /tmp/snowfall-migration-after-darwin.json
nix eval .#homeConfigurations --apply builtins.attrNames --json > /tmp/snowfall-migration-after-home.json
diff /tmp/snowfall-migration-baseline-nixos.json /tmp/snowfall-migration-after-nixos.json
diff /tmp/snowfall-migration-baseline-darwin.json /tmp/snowfall-migration-after-darwin.json
diff /tmp/snowfall-migration-baseline-home.json /tmp/snowfall-migration-after-home.json
```

Expected: no diff output on any of the three — identical output key lists before and after (`nixosConfigurations`: `orion`,`quasar`,`vortex`,`zenith`; `darwinConfigurations`: `astra`,`aurora`; `homeConfigurations`: all 8, including standalone `yash@apollo`/`yash@ares`).

- [ ] **Step 3: Build every darwin host**

Run:
```bash
cd /Users/yash/dotfiles
nix build .#darwinConfigurations.astra.system --no-link
nix build .#darwinConfigurations.aurora.system --no-link
```

Expected: both build successfully.

- [ ] **Step 4: Build every nixos host**

Run:
```bash
cd /Users/yash/dotfiles
for host in orion vortex zenith quasar; do
  echo "=== $host ==="
  nix build .#nixosConfigurations.$host.config.system.build.toplevel --no-link || echo "FAILED: $host"
done
```

Expected: all 4 hosts build successfully. (These may require your configured remote builders per `lib/nix-config` / `distributedBuilds = true` — that's unchanged from before this migration.)

- [ ] **Step 4b: Build the standalone home-manager configs (`apollo`, `ares` have no matching system)**

Run:
```bash
cd /Users/yash/dotfiles
nix build '.#homeConfigurations."yash@apollo".activationPackage' --no-link
nix build '.#homeConfigurations."yash@ares".activationPackage' --no-link
```

Expected: both build successfully. These are the two hosts with no `systems/` entry at all — Task 5's `mkStandaloneHome` is the only thing that builds them, so this step is the real regression check for that code path.

- [ ] **Step 5: Run the existing `just` recipes as a real-world sanity check**

Run:
```bash
cd /Users/yash/dotfiles
just check astra
```

Expected: succeeds identically to how it did before this migration (adjust host name to whichever machine you're running this from).

- [ ] **Step 6: `deploy-rs` check**

Run:
```bash
cd /Users/yash/dotfiles
nix flake check 2>&1 | grep -i deploy
```

Expected: no errors mentioning `deploy`.

- [ ] **Step 7: Final commit (if any validation fixes were needed)**

If Steps 1-6 required any fixes, commit them now with a message describing what was wrong:
```bash
git add -A
git commit -m "fix: <describe what validation caught>"
```

If no fixes were needed, this task produces no commit — validation-only.

---

## Post-migration manual check (not automated, do after merge)

Before relying on this for a real `deploy`/`darwin-rebuild switch`, on one low-risk host (e.g. `orion`, a VM) run the real activation and compare with `nvd`:

```bash
nixos-rebuild build --flake .#orion
nvd diff /run/current-system ./result
```

Confirm the diff shows no unexpected removals (a dropped module would show up here as missing packages/services, even if the build itself succeeded).
