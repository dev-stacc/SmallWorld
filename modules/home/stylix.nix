{ pkgs, inputs , ... } : {
    imports = [ inputs.stylix.homeManagerModules.stylix ];

    stylix = {
        enable = true;
        autoEnable = false;
        
        targets = {
            kitty.enable = true;
            hyprland.enable = true;
        };
    };
}