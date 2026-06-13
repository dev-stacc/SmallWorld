{ config, lib, pkgs, ... } : {
    programs = {
        dconf.enable = true;
        hyprland = {
            enable = true;
            xwayland.enable = true;
        };
    };
    
    environment.sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
    };
    
    environment.systemPackages = with pkgs; [
        libnotify
        hyprshot
        brightnessctl
        xdg-desktop-portal-termfilechooser
    ];

    xdg.portal = {
        enable = true;
        config.common = {
            "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
            "org.freedesktop.impl.portal.ScreenShot" = ["hyprland"];
            "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
            default = [
                "termfilechooser"
                "hyprland"
                "gtk"
            ];
        };
        extraPortals = with pkgs; [
            xdg-desktop-portal-termfilechooser
            xdg-desktop-portal-hyprland
            xdg-desktop-portal-gtk
        ];
    };
    
    systemd.user.services.kanshi = {
        description = "kanshi daemon";
        serviceConfig = {
            Type = "simple";
            ExecStart = ''${pkgs.kanshi}/bin/kanshi -C kanshi_config_file'';
        };
    };
}
