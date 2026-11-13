{ asterisk-jio, ... }:
_final: prev:
let
  system = prev.stdenv.hostPlatform.system;
in
prev.lib.optionalAttrs (builtins.hasAttr system asterisk-jio.packages) {
  asterisk = asterisk-jio.packages.${system}.asterisk-with-jio;
}
