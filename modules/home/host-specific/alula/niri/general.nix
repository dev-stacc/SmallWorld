{ ... }: {
    programs.niri.settings = {
        prefer-no-csd = true;

        spawn-at-startup = [
            { command = [ "waybar" ]; }
            { command = [ "xwayland-satellite" ]; }
        ];

        layout = {
            gaps = 6;
            border.width = 2;
        };
    };
}
