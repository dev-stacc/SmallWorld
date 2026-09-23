{ ... } : {
    programs.niri.settings.window-rules = [
        {
            geometry-corner-radius = {
                top-left     = 24.0;
                top-right    = 24.0;
                bottom-right = 24.0;
                bottom-left  = 24.0;
            };
            clip-to-geometry = true;
            opacity = 0.9;
        }
        {
            matches = [
                { title = "^kitty-launcher$"; }
                { title = "^kitty-control$"; }
            ];
            open-floating = true;
            default-column-width.fixed = 420;
            default-window-height.fixed = 195;
        }
        {
            matches = [ { app-id = "^librewolf$"; } ];
            opacity = 0.8;
        }
    ];
}
