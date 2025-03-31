{ lib, ... }:
{
  programs.fzf.colors = lib.mkForce {
    bg = "-1";
    "bg+" = "-1";
    fg = "-1";
    "fg+" = "-1";
    hl = "16";
    "hl+" = "17";
    info = "21";
    prompt = "2";
    pointer = "-1";
    marker = "21";
    spinner = "21";
    header = "1";
    border = "4";
    scrollbar = "dim";
  };
}
