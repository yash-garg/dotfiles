{
  pkgs,
  lib,
  namespace,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      age
      curl
      deploy-rs
      difftastic
      fd
      just
      jq
      mcporter
      mediainfo
      mtr
      nixfmt
      nurl
      pnpm
      ripgrep
      ripe-atlas-tools
      restic
      sops
      unzip
      whois
      wireguard-tools
      yq-go
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      pkgs.${namespace}.git-spr
    ];
}
