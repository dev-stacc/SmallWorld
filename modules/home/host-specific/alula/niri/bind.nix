{ username, ... }: let
    bin = "/home/${username}/.local/bin";
in {
    programs.niri.settings.binds = {
        "Mod+Return".action.spawn = [ "kitty" ];
        "Mod+D".action.spawn      = [ "kitty" "--title" "kitty-launcher" "-e" "${bin}/kitty-launcher" ];
        "Mod+E".action.spawn      = [ "kitty" "--title" "kitty-explorer" "-e" "yazi" ];

        "Mod+Q".action.close-window       = {};
        "Mod+F".action.fullscreen-window  = {};
        "Mod+Shift+C".action.quit         = {};

        "Mod+Left".action.focus-column-left   = {};
        "Mod+Right".action.focus-column-right = {};
        "Mod+Up".action.focus-window-up       = {};
        "Mod+Down".action.focus-window-down   = {};

        "Mod+Shift+Left".action.move-column-left   = {};
        "Mod+Shift+Right".action.move-column-right = {};
        "Mod+Shift+Up".action.move-window-up       = {};
        "Mod+Shift+Down".action.move-window-down   = {};

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        "Mod+Shift+4".action.move-window-to-workspace = 4;
        "Mod+Shift+5".action.move-window-to-workspace = 5;
        "Mod+Shift+6".action.move-window-to-workspace = 6;

        "XF86AudioMute".action.spawn        = [ "wpctl" "set-mute" "@DEFAULT_SINK@" "toggle" ];
        "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_SINK@" "5%-" ];
        "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_SINK@" "5%+" ];
        "XF86AudioMicMute".action.spawn     = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];

        "Print".action.screenshot        = {};
        "Shift+Print".action.screenshot-window = {};
    };
}
