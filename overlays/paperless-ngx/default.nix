_inputs: _final: prev: {
  paperless-ngx = prev.paperless-ngx.overrideAttrs (old: {
    pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "torch" ];
  });
}
