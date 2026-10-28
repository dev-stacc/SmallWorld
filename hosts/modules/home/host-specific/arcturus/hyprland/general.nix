{ theme, ... } : let
    colors = theme.base16;
in {
    general = {
        gaps_in = theme.window.gapsIn;
        gaps_out = "${toString theme.window.gapsV} ${toString theme.window.gapsH} ${toString theme.window.gapsV} ${toString theme.window.gapsH}";
        border_size = theme.window.border;
        locale = "en_CA";
        layout = "master";
        "col.active_border" = "rgba(${colors.base02}ff)";
        "col.inactive_border" = "rgba(${colors.base07}ff)";
    };
}
