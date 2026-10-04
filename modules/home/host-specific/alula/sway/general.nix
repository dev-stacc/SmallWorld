# Square by design: sway draws no corner rounding at all, and nothing here
# asks for any. Hard 2px borders and no titlebars, matching the flat/bevel
# aesthetic the rest of the config uses (border-radius 0 everywhere) and
# preserving the look niri had via prefer-no-csd.
{
    terminal = "kitty";

    gaps = {
        inner = 6;
        outer = 9;
    };

    window = {
        border = 2;
        titlebar = false;
    };

    floating = {
        border = 2;
        titlebar = false;
    };
}
