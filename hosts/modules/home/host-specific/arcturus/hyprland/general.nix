{ theme, ... } : let
    colors = theme.base16;
in {
    general = {
        gaps_in = 6;
        gaps_out = theme.tabs.width + theme.tabs.gap + theme.tabs.margin;
        border_size = theme.window.border;
        locale = "en_CA";
        layout = "master";
        "col.active_border" = "rgba(${colors.base02}ff)";
        "col.inactive_border" = "rgba(${colors.base07}ff)";
    };
}
