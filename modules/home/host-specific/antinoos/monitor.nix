{ ... }: {
    wayland.windowManager.hyprland.settings = {
        monitor = [
            "HDMI-A-2, preferred, auto, 1"
        ];

        render = {
            explicit_sync = 0;
            explicit_sync_kms = 0;
        };
    };
}
