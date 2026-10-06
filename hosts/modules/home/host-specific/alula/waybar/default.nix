{ lib, ... }: {
    programs.waybar.settings.mainBar = {
        modules-center = lib.mkForce [
            "group/audio"
            "sway/workspaces"
            "clock"
        ];
        "sway/workspaces" = {};
    };
}
