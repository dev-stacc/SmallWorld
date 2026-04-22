{
    enable = true;
    settings = {
        sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
        ];
        mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_previous_item()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
    };
}