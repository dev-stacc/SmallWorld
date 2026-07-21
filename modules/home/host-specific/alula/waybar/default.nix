{ lib, ... }: {
    programs.waybar.settings.mainBar = {
        modules-center = lib.mkForce [
            "group/audio"
            "niri/workspaces"
            "clock"
        ];
        "niri/workspaces" = {};
    };
}
