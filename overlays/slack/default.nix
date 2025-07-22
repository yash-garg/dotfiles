_: _final: prev: {
  slack = prev.slack.overrideAttrs (prevAttrs: {
    installPhase = prevAttrs.installPhase + ''
      rm $out/bin/slack

      makeWrapper $out/lib/slack/slack $out/bin/slack \
        --add-flags "--enable-features=WebRTCPipeWireCapturer" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--ozone-platform-hint=auto"
    '';
  });
}
