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
      fd
      just
      jq
      mediainfo
      mtr
      nixfmt
      nurl
      ripgrep
      restic
      sops
      unzip
      whois
      yq
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      difftastic
      pkgs.${namespace}.git-spr
      ripe-atlas-tools
    ];
}
