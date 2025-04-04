let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx1G6WZ4MQ8c4hUZy2Be+GF5fZQJSssn4qnJoQ4MPxz";
  alt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGT/WxAzpXRNz4AInl2lvZtegbKW0mZxzJjmMcAy1iOx";
  work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoj8ysWSPSV8T93j0YUtKhaaR71yoJQS553Yd1KqQLT";
  freelance = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINa4RyjHhuaFIwkeP9kWIyAPjfdPyam4LY6WdCO5JIKN";

  users = [
    main
    alt
  ];

  aurora = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5zDrFQlu00xY1AqRlYStqSdd8yFRVhylxY1iwtbkaV";
  astra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsXHN40eJNizwBCx98q/o4YYrQl+FBSgJWwdlNIjCfF";
  cosmos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFzLPmJL5Knew+jBin2NG/78lZfR0lNNWoUOeUTvdS6";
  nebula = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0oDlwxn0cKRuNrpb0neWGczQzQbQbX8fPkvc1zIcwe";
  nova = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4Sgn2sPpoVG1nAIZfS0bwmWRZyfKgsoymFzOt1pp0G";
  zenith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPm7C0lqhkp+TvLU9toLpL32Clgj+phKTbaSAzPLO8E";
in
{
  ".gitconfig-work.age".publicKeys = users ++ [ work ] ++ [ aurora ];
  ".gitconfig-freelance.age".publicKeys = users ++ [ freelance ] ++ [ astra ];

  "cosmos/tailscale.age".publicKeys = users ++ [
    cosmos
    zenith
  ];
  "cosmos/tailscale.env.age".publicKeys = users ++ [
    cosmos
    zenith
  ];
  "cosmos/user.age".publicKeys = users ++ [
    cosmos
    zenith
  ];

  "nebula/tailscale.age".publicKeys = users ++ [ nebula ];

  "nova/cifs.age".publicKeys = users ++ [ nova ];
  "nova/samba.age".publicKeys = users ++ [ nova ];

  "zenith/cloudflared.age".publicKeys = users ++ [ zenith ];
  "zenith/homepage.env.age".publicKeys = users ++ [ zenith ];
  "zenith/plausible.age".publicKeys = users ++ [ zenith ];
  "zenith/tailscale.age".publicKeys = users ++ [ zenith ];
  "zenith/tailscale.env.age".publicKeys = users ++ [ zenith ];
  "zenith/user.age".publicKeys = users ++ [ zenith ];
}
