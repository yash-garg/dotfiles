let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx1G6WZ4MQ8c4hUZy2Be+GF5fZQJSssn4qnJoQ4MPxz";
  alt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGT/WxAzpXRNz4AInl2lvZtegbKW0mZxzJjmMcAy1iOx";
  users = [
    main
    alt
  ];

  cosmos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFzLPmJL5Knew+jBin2NG/78lZfR0lNNWoUOeUTvdS6";
  nebula = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0oDlwxn0cKRuNrpb0neWGczQzQbQbX8fPkvc1zIcwe";
  nova = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4Sgn2sPpoVG1nAIZfS0bwmWRZyfKgsoymFzOt1pp0G";
  vortex = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2aT32IeITZcrNPSbZnrtbRqRdekmVr42sLHw6IL/h1";
in
{
  "cosmos/tailscale.age".publicKeys = users ++ [
    cosmos
    vortex
  ];
  "cosmos/user.age".publicKeys = users ++ [
    cosmos
    vortex
  ];

  "nebula/tailscale.age".publicKeys = users ++ [ nebula ];

  "nova/cifs.age".publicKeys = users ++ [ nova ];
  "nova/samba.age".publicKeys = users ++ [ nova ];

  "vortex/caddy.env.age".publicKeys = users ++ [ vortex ];
  "vortex/miniflux.env.age".publicKeys = users ++ [ vortex ];
  "vortex/tailscale.age".publicKeys = users ++ [ vortex ];
  "vortex/user.age".publicKeys = users ++ [ vortex ];
}
