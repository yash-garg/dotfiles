# Migrate off snowfall-lib

## Context

This repo's `flake.nix` is built on `snowfall-lib` (`snowfallorg/lib`).
Upstream now displays a "Call For Maintainers" notice: snowfall-lib has
been effectively unmaintained for some time, and the maintainer is
looking for someone to take it over. There is no guarantee it will
keep working across future `nixpkgs` bumps.

snowfall-lib currently provides four things this repo relies on:

1. **Host/home auto-discovery** — `systems/<arch>/<host>/default.nix`
   and `homes/<arch>/<user>@<host>/default.nix` are automatically
   turned into `nixosConfigurations`/`darwinConfigurations` and paired
   with a matching home-manager config by folder-name convention. No
   entries in `flake.nix` are required.
2. **Module auto-import** — every `modules/{nixos,darwin,home}/**/default.nix`
   file (129 total: 76 nixos, 42 home, 11 darwin) is automatically
   collected and imported. There is no explicit `imports = [...]` list
   anywhere in the repo today.
3. **Namespace plumbing** — the `namespace = "dots"` snowfall setting
   makes `lib.${namespace}` resolve to this repo's custom lib helpers
   (`mkOpt`, `mkBoolOpt`, `enabled`, `disabled`, from `lib/module/`)
   and `pkgs.${namespace}` resolve to this repo's custom packages
   (`git-spr`, etc). Used via `with lib.${namespace};` in 129 places
   and `config.${namespace}.*` / `namespace` module arg in 135 places.
4. **`snowfallorg.users.<user>.home.config`** — lets a NixOS/darwin
   system module inject home-manager config for a specific user
   without living in `homes/`. Used in 9 places.
5. **`snowfall.fs.get-file`** — resolves a path relative to the flake
   root, mostly used for `sops.secrets.*.sopsFile`. Used in ~30 places.
6. **Flake output assembly** — `channels-config`, `systems.modules`,
   `homes.modules`, `overlays`, `deploy` (`lib.mkDeploy`), `templates`,
   and `outputs-builder` (used only for the `treefmt` formatter) are
   all passed into `snowfall-lib.mkFlake`, which assembles the final
   flake outputs.

## Goals

- Remove the `snowfall-lib` flake input entirely.
- Preserve current behavior and ergonomics exactly:
  - New hosts/homes still just need a folder, no `flake.nix` edit.
  - New modules still just need a `default.nix` file, no `imports` edit.
  - The `dots.*` / `profiles.dots.*` / `shells.dots.*` option namespace
    and the `with lib.${namespace};` helper-call pattern keep working
    with **zero edits** to the 129+135 existing call sites.
- Replace the auto-discovery/namespace magic with a small, local,
  fully-readable library (`lib/autoload/`) that does only what this
  repo needs — not a general-purpose framework.
- Ship as a single PR; validate all 9 hosts build before merging.

## Non-goals

- No change to what any host/module actually configures. This is a
  pure plumbing swap — behavior must be identical before and after.
- No flattening of the `dots` namespace convention (options, lib
  helpers, package overlay) — it's being kept, just reimplemented
  locally.
- No introduction of `flake-parts` or another flake framework as a
  replacement — going framework-to-framework doesn't address the
  "unmaintained dependency" risk this migration exists to fix.
- No reorganization of `modules/nixos/services/` or other structural
  cleanups identified separately (secrets scoping, docs, etc.) — those
  are separate, smaller pieces of work and out of scope here.

## Architecture

`snowfall-lib.mkLib`/`mkFlake` is replaced by:

- `lib/autoload/tree.nix` — generic recursive `default.nix` finder.
- `lib/autoload/systems.nix` — builds `nixosConfigurations`/
  `darwinConfigurations` from `systems/`, auto-attaching the matching
  `homes/` config as `home-manager.users.<user>` by folder-name
  convention.
- `lib/autoload/namespace.nix` — extends `lib` with `lib.dots.*`
  (including `lib.dots.get-file`, replacing `snowfall.fs.get-file`) and
  `pkgs` with `pkgs.dots.*`.

`flake.nix` is rewritten to call these directly instead of delegating
to `snowfall-lib.mkFlake`.

## Components

### `lib/autoload/tree.nix`

```nix
# Recursively find every `default.nix` under `dir`, relative to `dir`.
# Returns a list of paths.
{ lib }:
dir:
let
  walk =
    base: relPath:
    let
      entries = builtins.readDir (base + "/${relPath}");
      recurse = name: type: 
        let path = if relPath == "" then name else "${relPath}/${name}"; in
        if type == "directory" then
          walk base path
        else if name == "default.nix" && relPath != "" then
          [ (base + "/${path}") ]
        else
          [ ];
    in
    lib.flatten (lib.mapAttrsToList recurse entries);
in
walk dir ""
```

Used for `modules/nixos`, `modules/darwin`, `modules/home` — each
becomes `import "${lib.autoload.tree modulesDir}"` fed as the base
`imports` list for that module class.

### `lib/autoload/systems.nix`

For each `systems/<arch>/<host>/default.nix`:

- Determine `arch` (`aarch64-darwin`, `aarch64-linux`, `x86_64-linux`)
  and dispatch to `nix-darwin.lib.darwinSystem` (for `*-darwin`) or
  `nixpkgs.lib.nixosSystem` (for `*-linux`).
- Look for a matching `homes/<arch>/<user>@<host>/default.nix`. If
  found, extract `<user>` from the folder name and add a
  `home-manager.users.<user> = import <that file>` module, plus the
  standard `home-manager.nixosModules.home-manager` /
  `.darwinModules.home-manager` module.
- Pass `specialArgs`/`extraSpecialArgs` containing: `namespace = "dots"`,
  `lib` (extended, see below), the module auto-import lists, and
  anything else currently supplied by snowfall (e.g. `ports`,
  `trusted-proxies` from existing `lib/`).

Host-to-arch mapping is derived from the `systems/<arch>/...` folder
structure itself, same as today — no hand-written per-host list is
needed, matching the "keep it consistent" decision.

### `lib/autoload/namespace.nix`

```nix
{ lib, pkgs, ... }:
{
  lib = lib.extend (final: _prev: {
    dots = import ../module { lib = final; } // {
      get-file = relPath: ../../. + "/${relPath}";
    };
  });
  pkgs = pkgs.extend (final: _prev: {
    dots = import ../../packages { pkgs = final; };
  });
}
```

`get-file` folds into `lib.dots` rather than being a separate
top-level thing, since it's conceptually the same "custom namespace
helper" bucket as `mkOpt`/`enabled`/etc.

### Mechanical replacements

- `snowfallorg.users.<user>.home.config = { ... }` → `home-manager.users.<user> = { ... }`. 9 sites: `systems/aarch64-darwin/{astra,aurora}/default.nix`, `modules/nixos/desktop/{android-dev,gnome,stylix}/default.nix`, `modules/darwin/{homebrew,user}/default.nix`.
- `snowfall.fs.get-file "secrets/x"` → `lib.dots.get-file "secrets/x"`. ~30 sites across `systems/`, `modules/home/{env,git}`, `modules/nixos/services/*`, `modules/darwin/homebrew`.
- `modules/home/user/default.nix` (`config.snowfallorg.user.name` /
  `.home.directory`) → since `lib/autoload/systems.nix` already knows
  the username when it wires up `home-manager.users.<user>`, this
  module instead reads `home.username`/`home.homeDirectory` set by
  home-manager itself by default — this file likely becomes
  unnecessary and can be deleted, pending confirmation during
  implementation that nothing else depends on it.

### `flake.nix`

Replaces the `snowfall-lib.mkLib`/`mkFlake` call with:

- `nixpkgs.lib.genAttrs supportedSystems` for per-system `pkgs`
  instantiation (`import nixpkgs { inherit system overlays; config = channels-config; }`), where `overlays` is the existing flat list (`copyparty`, `nur`, plus local `overlays/*`) and `channels-config` is the existing `allowUnfree`/`cudaSupport`/`permittedInsecurePackages` attrset, unchanged.
- `nixosConfigurations`/`darwinConfigurations` from `lib/autoload/systems.nix`.
- `deploy` output: unchanged, `lib/deploy` already only depends on `self.nixosConfigurations`.
- `checks.<system>.deploy`: unchanged, already only depends on `inputs.deploy-rs`/`self.deploy`.
- `templates`: copied as-is (already plain data, not snowfall-dependent).
- `formatter.<system>`: set directly per system using the existing `treefmt-nix` module eval, replacing the `outputs-builder` indirection.
- `packages`/`overlays.default`: exposes `pkgs.dots.*` for external consumers (this replaces the root `default.nix` shim's purpose, though that file can stay as-is since it's independent).

## Migration plan

Single PR, in this order (all within one branch, one commit or logically-grouped commits, merged together):

1. Add `lib/autoload/{tree,systems,namespace}.nix`.
2. Rewrite `flake.nix` to stop referencing `snowfall-lib` and wire up the new autoload helpers.
3. Do the ~40 mechanical replacements (`snowfallorg.users.*` → `home-manager.users.*`, `snowfall.fs.get-file` → `lib.dots.get-file`).
4. Delete/update `modules/home/user/default.nix` as needed.
5. Remove `snowfall-lib` from `flake.nix` `inputs`, run `nix flake update snowfall-lib` removal / `nix flake lock` to drop it from `flake.lock`.
6. Validate (see below).

## Testing / validation

- `nix flake check` passes.
- Every host builds successfully and produces the same store path
  category as before (spot-check via `nix build --dry-run` diff isn't
  required, but a successful build of each is):
  - `nom build .#darwinConfigurations.{astra,aurora}.system`
  - `nom build .#nixosConfigurations.{orion,vortex,zenith,quasar,apollo,ares}.config.system.build.toplevel`
- Each host's home-manager activation package builds (covered by the
  above, since home-manager is wired in as a NixOS/darwin module here,
  not standalone).
- `just check <host>` (existing recipe) works unchanged for all hosts.
- `deploy-rs` check (`nix flake check` covers `checks.<system>.deploy`) passes.
- CI (`cache-nixos.yml`) passes on the PR.
- `nix flake show` output is manually compared before/after to confirm
  the same set of `nixosConfigurations`/`darwinConfigurations`/
  `homeConfigurations` keys exist.

## Risks

- **Silent module drop**: if `lib/autoload/tree.nix` has a bug, a
  module could silently fail to import. Mitigated by comparing
  `nix eval` module-count / option-count before and after, and by the
  full-build validation above (a missing service module would show up
  as a missing systemd unit, etc., not just a build failure — worth an
  extra manual read-through of `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` diffs isn't sufficient; a config-level diff via `nixos-rebuild build` + `nvd diff` against current `/run/current-system` on a real host is the strongest check before deploying).
- **home-manager username inference**: removing
  `snowfallorg.users.*.name/.home.directory` needs care — confirm the
  replacement produces the same `home.username`/`home.homeDirectory`
  for every host (usernames differ: `yash` vs `ygarg`).
- **`flake.lock` churn**: removing `snowfall-lib` and its transitive
  inputs (`flake-utils-plus`, etc.) will change `flake.lock`; confirm
  no other input still needs something `snowfall-lib` was pinning.
