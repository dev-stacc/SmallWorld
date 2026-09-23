{ config, pkgs, ... } : {
    home.packages = with pkgs; [
        swaybg
    ];

    programs.niri.settings.spawn-at-startup = [
        { command = [ "swaybg" "-m" "fill" "-i" "${config.stylix.image}" ]; }
    ];
}
