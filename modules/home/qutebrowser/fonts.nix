{ config, lib, pkgs, fontName, ... } : {
    fonts = lib.mkForce {
        default_family = fontName;
        tabs = {
            selected = "bold 9pt ${fontName}";
            unselected = "9pt ${fontName}";
        };
        statusbar = "9pt ${fontName}";
        completion.entry = "9pt ${fontName}";
    };
}