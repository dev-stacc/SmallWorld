{ ... } : {
    programs.niri.settings.outputs = {
        "eDP-1" = {
            mode = { width = 1920; height = 1080; refresh = 30.0; };
            scale = 1;
            position = { x = 0; y = 0; };
        };
        "HDMI-A-1".position = { x = 1920; y = 0; };
        "HDMI-A-2".position = { x = 3840; y = 0; };
    };
}
