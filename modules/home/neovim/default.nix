{ config, pkgs, ... } : {
    programs.neovim = {
        enable = true;
        
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        
        plugins = with pkgs.vimPlugins; [
            nvim-lspconfig
            
            comment-nvim
            
            neo-tree-nvim
            
            telescope-nvim
            telescope-fzf-native-nvim
            
            
            
        ];
        
        extraLuaConfig = ''
            ${builtins.readFile ./nvim/options.lua}
        '';
    };
}