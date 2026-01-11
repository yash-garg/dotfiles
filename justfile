default:
    @just --list --unsorted

deploy:
    #!/usr/bin/env bash
    if [[ $(uname) == "Darwin" ]]; then
        sudo darwin-rebuild switch --flake .
    else
        sudo nixos-rebuild switch --flake .
    fi

debug:
    nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

update:
    nix flake update

history:
    nix profile history --profile /nix/var/nix/profiles/system

gc:
    sudo nix-collect-garbage --delete-old

darwin-check:
    nom build .#darwinConfigurations.trinity.system

topology sys:
    nom build .#topology.{{ sys }}.config.output

eval conf:
    nix eval .#{{ conf }} --apply builtins.attrNames --json

template name path:
    nix flake new --template .#templates.{{ name }} {{ path }}

check flake:
    #!/usr/bin/env bash
    if [[ $(uname) == "Darwin" ]]; then
        nom build .#darwinConfigurations.{{ flake }}.system
    else
        nom build .#nixosConfigurations.{{ flake }}.config.system.build.toplevel
    fi

update-keys:
    fd . secrets -t f -x sops updatekeys -y {}
