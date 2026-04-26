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
        WLR_DRM_NO_MODIFIERS = "1";
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        LIBVA_DRIVER_NAME = "iHD";
    };
    
    environment.systemPackages = with pkgs; [
        libnotify
        hyprshot
        brightnessctl
    ];
    
    xdg.portal = {
        enable = true;
        config.common = {
            "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
            "org.freedesktop.impl.portal.ScreenShot" = [ "hyprland" ];
            default = [
                "hyprland"
                "gtk"
            ];
        };
        extraPortals = with pkgs; [
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
