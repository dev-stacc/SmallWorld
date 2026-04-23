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
    };
    
    environment.systemPackages = [
        pkgs.libnotify
        pkgs.hyprshot
        pkgs.brightnessctl
    ];
    
    xdg.portal = {
        enable = true;
        config.common.default = "*";
        extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
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
