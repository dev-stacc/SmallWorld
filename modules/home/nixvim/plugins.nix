 {
    nvim-tree = import ./nvimtree.nix;
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
