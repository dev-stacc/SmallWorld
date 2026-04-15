{ pkgs, ... } : {
    stylix = {
        enable = true;
        autoEnable = false;
        image = "./wallpapers/stillPit.png";
        
        targets = {
            kitty.enable = true;
            hyprland.enable = true;
        };
    };
}