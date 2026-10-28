{ theme, ... } : let
    ds = toString (theme.anim.ms / 100);
in {
    animations = {
        enabled = true;

        bezier = [ "snap, 0.22, 1, 0.3, 1" ];

        animation = [
            "windows, 1, ${ds}, snap, slide"
            "windowsOut, 1, ${ds}, snap, slide"
            "border, 1, ${ds}, snap"
            "fade, 1, ${ds}, snap"
            "workspaces, 1, ${ds}, snap, slide"
        ];
    };
}
