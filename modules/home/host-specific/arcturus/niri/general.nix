{ config, ... } : let
    colors = config.stylix.base16Scheme;
in {
    programs.niri.settings = {
        prefer-no-csd = true;

        spawn-at-startup = [
            { command = [ "xwayland-satellite" ]; }
        ];

        layout = {
            gaps = 6;

            focus-ring.enable = false;

            border = {
                enable = true;
                width = 2;
                active.color = "#${colors.base02}ff";
                inactive.color = "#${colors.base01}00";
            };

            shadow = {
                enable = true;
                softness = 9;
            };
        };
    };
}
