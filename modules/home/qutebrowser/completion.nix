{ config, lib, pkgs, ... } : {
    completion.scrollbar = lib.mkForce {
        padding = 0;
        width = 0;
    };
}