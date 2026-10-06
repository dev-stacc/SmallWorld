local palette = {
    base00 = "theme.base00",
    base01 = "theme.base01",
    base02 = "theme.base02",
    base03 = "theme.base03",
    base04 = "theme.base04",
    base05 = "theme.base05",
    base06 = "theme.base06",
    base07 = "theme.base07",
    base08 = "theme.base08",
    base09 = "theme.base09",
    base0A = "theme.base0A",
    base0B = "theme.base0B",
    base0C = "theme.base0C",
    base0D = "theme.base0D",
    base0E = "theme.base0E",
    base0F = "theme.base0F"
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
