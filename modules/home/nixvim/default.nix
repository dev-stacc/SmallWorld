{ config, lib, pkgs, ... } : let 
    colors = config.stylix.base16Scheme;
in {
    programs.nixvim = {
        enable = true;
        defaultEditor = true;
        
        globals.mapleader = " ";
        
        opts = import ./opts.nix;
        lsp = import ./lsp.nix;
        treesitter = import ./treesitter.nix;
        cmp = import ./cmp.nix;
        snacks = import ./snacks.nix;
        plugins = import ./plugins.nix;

        luasnip.enable = true;

    extraConfigLua = ''
        local palette = {
            base00 = "#${colors.base00}",
            base01 = "#${colors.base01}",
            base02 = "#${colors.base02}",
            base03 = "#${colors.base03}",
            base04 = "#${colors.base04}",
            base05 = "#${colors.base05}",
            base06 = "#${colors.base06}",
            base07 = "#${colors.base07}",
            base08 = "#${colors.base08}",
            base09 = "#${colors.base09}",
            base0A = "#${colors.base0A}",
            base0B = "#${colors.base0B}",
            base0C = "#${colors.base0C}",
            base0D = "#${colors.base0D}",
            base0E = "#${colors.base0E}",
            base0F = "#${colors.base0F}"
        }

        vim.cmd("hi clear")
        vim.o.termguicolors = true

        vim.api.nvim_set_hl(0, "Normal", {
            bg = "none",
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "Comment", {
            fg = palette.base05
        })
        vim.api.nvim_set_hl(0, "Constant", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "String", {
            fg = palette.base05
        })
        vim.api.nvim_set_hl(0, "Identifier", {
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "Function", {
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "Statement", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "PreProc", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "Type", {
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "Special", {
            fg = palette.base04
        })
        vim.api.nvim_set_hl(0, "Underlined", {
            fg = palette.base05, undercurl = true
        })
        vim.api.nvim_set_hl(0, "Error", {
            fg = palette.base04
        })
        vim.api.nvim_set_hl(0, "Todo", {
            fg = palette.base04
        })

        vim.api.nvim_set_hl(0, "LineNr", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "CursorLineNr", {
            fg = palette.base02
        })

        vim.api.nvim_set_hl(0, "StatusLine", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "StatusLineNC", {
            bg = none,
            fg = palette.base03
        })

        vim.api.nvim_set_hl(0, "Search", {
            bg = palette.base00,
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "IncSearch", {
            bg = palette.base00,
            fg = palette.base03
        })

        vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", {
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "NvimTreeFileIcon", {
            fg = palette.base03
        })
        vim.api.nvim_set_hl(0, "NvimTreeFolderName", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeExecFile", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeSymlink", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeFile", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeWindowPicker", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeNormal", {
            fg = palette.base02
        })
        vim.api.nvim_set_hl(0, "NvimTreeRootFolder", {
            fg = palette.base02
        })
    '';

        keymaps = [
            {
                key = "<leader>e";
                action = "<cmd>NvimTreeToggle<CR>";
                mode = "n";
                options.desc = "Toggle file explorer";
            }
            {
                key = "<leader>ff";
                action = "<cmd>Snacks picker files<CR>";
                mode = "n";
                options.desc = "Find files";
            }
            {
                key = "<leader>fg";
                action = "<cmd>Snacks picker grep<CR>";
                mode = "n";
                options.desc = "Live grep";
            }
            {
                key = "<leader>fr";
                action = "<cmd>Snacks picker oldfiles<CR>";
                mode = "n";
                options.desc = "Recent files";
            }
            {
                key = "gd";
                action = "<cmd>lua vim.lsp.buf.definition()<CR>";
                mode = "n";
                options.desc = "Go to definition";
            }
            {
                key = "K";
                action = "<cmd>lua vim.lsp.buf.hover()<CR>";
                mode = "n";
                options.desc = "Hover documentation";
            }
            {
                key = "<leader>rn";
                action = "<cmd>lua vim.lsp.buf.rename()<CR>";
                mode = "n";
                options.desc = "Rename symbol";
            }
            {
                key = "<leader>ca";
                action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
                mode = "n";
                options.desc = "Code actions";
            }
            {
                key = "gr";
                action = "<cmd>lua vim.lsp.buf.references()<CR>";
                mode = "n";
                options.desc = "Go to references";
            }
            {
                key = "gI";
                action = "<cmd>lua vim.lsp.buf.implementation()<CR>";
                mode = "n";
                options.desc = "Go to implementation";
            }
            {
                key = "<leader>d";
                action = "<cmd>lua vim.diagnostic.open_float()<CR>";
                mode = "n";
                options.desc = "Show diagnostics";
            }
            {
                key = "]d";
                action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
                mode = "n";
                options.desc = "Next diagnostic";
            }
            {
                key = "[d";
                action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
                mode = "n";
                options.desc = "Previous diagnostic";
            }
            {
                key = "<esc>";
                action = "<cmd>nohlsearch<CR>";
                mode = "n";
                options.desc = "Clear search";
            }
            {
                key = "<C-s>";
                action = "<cmd>write<CR>";
                mode = ["n" "i"];
                options.desc = "Save file";
            }
            {
                key = "<leader>q";
                action = "<cmd>qa<CR>";
                mode = "n";
                options.desc = "Quit all";
            }
        ];
    };
}
