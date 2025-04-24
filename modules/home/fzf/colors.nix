{ lib, ... }:
{
  programs.fzf.colors = lib.mkForce {
    bg = "-1";
    "bg+" = "-1";
    fg = "-1";
    "fg+" = "-1";
    hl = "red";
    "hl+" = "red";
    info = "blue";
    prompt = "green";
    pointer = "cyan";
    marker = "blue";
    spinner = "blue";
    header = "green";
    border = "blue";
    scrollbar = "dim";
  };
}
