{ config, lib, pkgs, fontName, ... } : {
    fonts = lib.mkForce {
        default_family = fontName;
        tabs = {
            selected = "bold 11pt ${fontName}";
            unselected = "11pt ${fontName}";
        };
        statusbar = "11pt ${fontName}";
        completion.entry = "11pt ${fontName}";
    };
}