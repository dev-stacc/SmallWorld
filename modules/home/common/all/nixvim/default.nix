{ config, lib, pkgs, username, ... } : let
    extras = import ./extra-config-lua/default.nix {
        inherit config lib pkgs;
    };
in {
    programs.nixvim = {
        enable = true;
        defaultEditor = true;

        globals.mapleader = " ";

        opts = import ./opts.nix { inherit username; };
        lsp = import ./lsp.nix;
        treesitter = import ./treesitter.nix;
        cmp = import ./cmp.nix;
        keymaps = import ./keymaps.nix;
        luasnip.enable = true;

        extraConfigLua = extras.extraConfigLua;

        plugins = {
            web-devicons.enable = true;
            telescope = import ./telescope.nix;
            nvim-tree = import ./nvimtree.nix;
            transparent = import ./transparent.nix;
        };
    };
}
