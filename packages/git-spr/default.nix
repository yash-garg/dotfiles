{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "git-spr";
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "ejoffe";
    repo = "spr";
    tag = "v${version}";
    hash = "sha256-477ERmc7hQzbja5qWLI/2zz8gheIEpmMLQSp2EOjjMY=";
  };

  vendorHash = "sha256-vTmzhU/sJ0C8mYuLE8qQQELI4ZwQVv0dsM/ea1mlhFk=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.commit=${src.rev}"
    "-X main.date=1970-01-01T00:00:00Z"
    "-X main.builtBy=nixpkgs"
  ];

  postInstall = ''
    mv $out/bin/amend $out/bin/git-amend
    mv $out/bin/reword $out/bin/spr_reword_helper
    mv $out/bin/spr $out/bin/git-spr
  '';

  meta = with lib; {
    description = "Stacked Pull Requests on GitHub";
    homepage = "https://github.com/ejoffe/spr";
    license = licenses.mit;
    maintainers = [ ];
  };
}
