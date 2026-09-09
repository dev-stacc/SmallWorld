local npairs = require('nvim-autopairs')

npairs.setup({
  pairs = {
    ['{'] = '}',
    ['['] = ']',
    ['('] = ')',
    ['<'] = '>',
    ['`'] = '`',
    ['*'] = '*',
    ['"'] = '"',
    ["'"] = "'",
  },
})

local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
