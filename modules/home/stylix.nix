{ config, pkgs, inputs , ... } : {
    imports = [ inputs.stylix.homeManagerModules.stylix ];

    stylix = {
        enable = true;
        autoEnable = true;
        
        targets = {
            kitty.enable = true;
            hyprland.enable = true;
        };
    };
}