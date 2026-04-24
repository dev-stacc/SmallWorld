local palette = {
    base00 = "stylix.base00",
    base01 = "stylix.base01",
    base02 = "stylix.base02",
    base03 = "stylix.base03",
    base04 = "stylix.base04",
    base05 = "stylix.base05",
    base06 = "stylix.base06",
    base07 = "stylix.base07",
    base08 = "stylix.base08",
    base09 = "stylix.base09",
    base0A = "stylix.base0A",
    base0B = "stylix.base0B",
    base0C = "stylix.base0C",
    base0D = "stylix.base0D",
    base0E = "stylix.base0E",
    base0F = "stylix.base0F"
}

vim.cmd("hi clear")
vim.o.termguicolors = true

vim.api.nvim_set_hl(0, "Normal", {
    bg = nil,
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
    fg = palette.base05,
    undercurl = true
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
    bg = nil,
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
