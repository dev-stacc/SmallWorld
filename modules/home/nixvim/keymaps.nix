[
    {
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<CR>";
        mode = "n";
        options.desc = "Toggle file explorer";
    }
    {
        key = "<leader>q";
        action = "<cmd>qa<CR>";
        mode = "n";
        options.desc = "Quit all";
    }
    {
        key = "<C-s>";
        action = "<cmd>write<CR>";
        mode = ["n" "i"];
        options.desc = "Save file";
    }
    {
        key = "<esc>";
        action = "<cmd>nohlsearch<CR>";
        mode = "n";
        options.desc = "Clear search highlight";
    }
    
   
 
    {
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        mode = "n";
        options.desc = "Find files";
    }
    {
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        mode = "n";
        options.desc = "Live grep";
    }
    {
        key = "<leader>fr";
        action = "<cmd>Telescope oldfiles<CR>";
        mode = "n";
        options.desc = "Recent files";
    }
    {
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        mode = "n";
        options.desc = "Buffers";
    }
    {
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<CR>";
        mode = "n";
        options.desc = "Help tags";
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
]
