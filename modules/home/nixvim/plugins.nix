 {
    nvim-tree = import ./nvimtree.nix;
    mini = {
        enable = true;
        modules = ["base16"];
    };
    transparent = {
        enable = true;
        settings = {
            autostart = true;
            extra_groups = [
                "Normal"
                "NormalNC"
                "EndOfBuffer"
                "SignColumn"
                "LineNr"
                "CursorLineNr"
                "FoldColumn"
            ];
        };
    };
}
