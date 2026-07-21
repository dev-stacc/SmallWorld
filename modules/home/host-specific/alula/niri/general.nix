{ ... }: {
    programs.niri.settings = {
        prefer-no-csd = true;

        spawn-at-startup = [
            { command = [ "waybar" ]; }
        ];

        layout = {
            gaps = 6;
            border.width = 2;
        };
    };
}
