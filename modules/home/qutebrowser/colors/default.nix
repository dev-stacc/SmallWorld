{ config, lib, pkgs, ... } : let
    completion = import ./completion.nix { inherit config lib pkgs; };
#    webpage = import ./webpage.nix { inherit config lib pkgs; };
    tabs = import ./tabs.nix { inherit config lib pkgs; };
    statusbar = import ./statusbar.nix { inherit config lib pkgs; };
    tooltip = import ./tooltip.nix { inherit config lib pkgs; };
in {
    colors = lib.mkMerge [
        completion
#        webpage
        tabs
        statusbar
        tooltip
    ];
}