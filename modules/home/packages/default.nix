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
      mediainfo
      mtr
      nixfmt
      nurl
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
