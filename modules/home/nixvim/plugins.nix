 {
    nvim-tree = import ./nvimtree.nix;
    web-devicons.enable = true;
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
