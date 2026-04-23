{ config, lib, pkgs, ... } : let 
    extras = import ./extra-config-lua/default.nix {
        inherit config lib pkgs;
    };
in {
    programs.nixvim = {
        enable = true;
        defaultEditor = true;
        
        globals.mapleader = " ";
        
        opts = import ./opts.nix;
        lsp = import ./lsp.nix;
        treesitter = import ./treesitter.nix;
        cmp = import ./cmp.nix;
        plugins = import ./plugins.nix;
        keymaps = import ./keymaps;
        plugins.telescope = ./telescope.nix;
        plugins.nvim-tree = import ./nvimtree;
        plugins.transparent = import ./transparent;
        web-devicons.enable = true;

        luasnip.enable = true;
        extraConfigLua = extras.extraConfigLua;
    };
}
