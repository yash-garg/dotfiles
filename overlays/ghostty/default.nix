{ ghostty, ... }: _final: prev: { ghostty = ghostty.packages.${prev.system}.ghostty-releasefast; }
