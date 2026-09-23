{ pkgs, ... } : {
    programs = {
        dconf.enable = true;
        xwayland.enable = true;
    };

    environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
        XDG_CURRENT_DESKTOP = "niri";
    };

    environment.systemPackages = with pkgs; [
        libnotify
        brightnessctl
        grim
        slurp
        wl-clipboard
        xwayland-satellite
        xdg-desktop-portal-termfilechooser
    ];

    xdg.portal = {
        enable = true;
        config.common = {
            "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
            "org.freedesktop.impl.portal.ScreenShot" = ["wlr"];
            "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
            default = [
                "termfilechooser"
                "wlr"
                "gtk"
            ];
        };
        extraPortals = with pkgs; [
            xdg-desktop-portal-termfilechooser
            xdg-desktop-portal-wlr
            xdg-desktop-portal-gtk
        ];
    };
}
