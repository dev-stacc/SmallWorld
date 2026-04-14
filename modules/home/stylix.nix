{ pkgs, ... } : {
    stylix = {
        enable = true;
        autoEnable = false;
        
        targets = {
            kitty.enable = true;
            hyprland.enable = true;
        };
    };
}