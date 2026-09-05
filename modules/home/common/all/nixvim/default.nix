{ config, lib, pkgs, inputs, username, ... } : let
    extras = import ./extra-config-lua/default.nix {
        inherit config lib pkgs;
    };
in {
    programs.nixvim = {
        enable = true;
        defaultEditor = true;

        globals.mapleader = " ";

        opts = import ./opts.nix { inherit username; };
        keymaps = import ./keymaps.nix;
        extraConfigLua = extras.extraConfigLua;

        plugins = {
            web-devicons.enable = true;
            telescope = import ./telescope.nix;
            nvim-tree = import ./nvimtree.nix;
            transparent = import ./transparent.nix;
            cmp = import ./cmp.nix;
            lsp = import ./lsp.nix;
            luasnip.enable = true;
            autopairs.enable = true;
            treesitter = import ./treesitter.nix;
            gitsigns.enable = true;
            diffview.enable = true;
        };
    };
}
