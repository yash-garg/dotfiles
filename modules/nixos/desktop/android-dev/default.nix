{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.android-dev;
  defaultJdk = pkgs.openjdk17;
  toolchains = [
    pkgs.openjdk11
    pkgs.openjdk21
    defaultJdk
  ];
  mapOpenJdk = pkg: "${pkg}/lib/openjdk";
in
{
  options.${namespace}.desktop.android-dev = {
    enable = mkEnableOption "Configure a development environment for Android apps";
  };

  config = mkIf cfg.enable {
    users.users.yash.packages = with pkgs; [
      android-tools
      androidStudioPackages.stable
      androidStudioPackages.beta
      apktool
      flutter
      kotlin
      scrcpy
      maestro
    ];

    programs = {
      adb = enabled;
      java = enabled // {
        package = defaultJdk;
        binfmt = false;
      };
      nix-ld = enabled // {
        package = pkgs.nix-ld;
        libraries = with pkgs; [
          icu
          openssl
          stdenv.cc.cc
          zlib
        ];
      };
    };

    home-manager.users.yash = {
      programs.gradle = enabled // {
        settings = {
          "org.gradle.caching" = true;
          "org.gradle.parallel" = true;
          "org.gradle.jvmargs" = "-XX:MaxMetaspaceSize=1024m -XX:+UseG1GC";
          "org.gradle.java.home" = mapOpenJdk defaultJdk;
          "org.gradle.java.installations.auto-detect" = false;
          "org.gradle.java.installations.auto-download" = false;
          "org.gradle.java.installations.paths" = lib.concatMapStringsSep "," mapOpenJdk toolchains;
        };
      };
    };
  };
}
