{ theme, ... } : let
    ds = toString (theme.anim.ms / 100);
in {
    animations = {
        enabled = true;

        bezier = [ "snap, 0.22, 1, 0.3, 1" ];

        animation = [
            "windows, 0"
            "windowsIn, 0"
            "windowsOut, 0"
            "windowsMove, 0"
            "border, 0"
            "fade, 0"
            "workspaces, 1, ${ds}, snap, slide"
        ];
    };
}
