let
    mod = "Mod4";
    ss = "$HOME/Pictures/Screenshots";
in {
    modifier = mod;

    keybindings = {
        "${mod}+Return" = "exec kitty";
        "${mod}+d"      = "exec pkill kitty-launcher || kitty --title kitty-launcher -e ~/.local/bin/kitty-launcher";
        "${mod}+n"      = "exec pkill kitty-control || kitty --title kitty-control -e ~/.local/bin/kitty-control";
        "${mod}+e"      = "exec pkill yazi || kitty --title kitty-explorer -e yazi";

        "${mod}+Shift+c" = "reload";
        "${mod}+m"       = "exit";
        "${mod}+q"       = "kill";
        "${mod}+f"       = "fullscreen toggle";

        "${mod}+Left"       = "focus left";
        "${mod}+Right"      = "focus right";
        "${mod}+Up"         = "focus up";
        "${mod}+Down"       = "focus down";
        "${mod}+Shift+Left"  = "move left";
        "${mod}+Shift+Right" = "move right";
        "${mod}+Shift+Up"    = "move up";
        "${mod}+Shift+Down"  = "move down";

        "${mod}+Shift+Space" = "floating toggle";
        "${mod}+Space"       = "focus mode_toggle";
        "${mod}+r"           = "mode resize";

        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";

        "XF86AudioMute"        = "exec wpctl set-mute @DEFAULT_SINK@ toggle";
        "XF86AudioLowerVolume" = "exec wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%-";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+";
        "XF86AudioMicMute"     = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        "Print"       = "exec mkdir -p ${ss} && grim ${ss}/$(date +%Y%m%d_%H%M%S).png";
        "Shift+Print" = "exec mkdir -p ${ss} && grim -g \"$(slurp)\" ${ss}/$(date +%Y%m%d_%H%M%S).png";
    };

    modes = {
        resize = {
            "Left"   = "resize shrink width 20 px";
            "Right"  = "resize grow width 20 px";
            "Up"     = "resize shrink height 20 px";
            "Down"   = "resize grow height 20 px";
            "Return" = "mode default";
            "Escape" = "mode default";
        };
    };
}
