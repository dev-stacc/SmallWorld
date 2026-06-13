{ pkgs, ... }: {
    programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
    };

    environment.sessionVariables = {
        NIXOS_OZONE_WL             = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME       = "xdgdesktopportal";
        XDG_CURRENT_DESKTOP        = "sway";
        WLR_DRM_NO_ATOMIC          = "1";
    };

    environment.systemPackages = with pkgs; [
        libnotify
        grim
        slurp
        wl-clipboard
        xdg-desktop-portal-termfilechooser
    ];

    xdg.portal = {
        enable = true;
        config.common = {
            "org.freedesktop.impl.portal.ScreenCast"  = [ "wlr" ];
            "org.freedesktop.impl.portal.ScreenShot"  = [ "wlr" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
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
