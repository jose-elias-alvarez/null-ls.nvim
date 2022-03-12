local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local COMPLETION = methods.internal.COMPLETION

return h.make_builtin({
    name = "vsnip",
    meta = {
        url = "https://github.com/hrsh7th/vim-vsnip",
        description = "Snippets managed by vim-vsnip.",
        notes = {
            "Registering this source will show available snippets in the completion list, but vim-vsnip is in charge of expanding them. See [vim-vsnip's documentation](https://github.com/hrsh7th/vim-vsnip#2-setting) for setup instructions.",
        },
    },
    method = COMPLETION,
    filetypes = {},
    generator = {
        fn = function(params, done)
            local items = {}
            local snips = vim.fn["vsnip#get_complete_items"](params.bufnr)
            local targets = vim.tbl_filter(function(item)
                return string.match(item.word, "^" .. params.word_to_complete)
            end, snips)
            for _, item in ipairs(targets) do
                table.insert(items, {
                    label = item.abbr,
                    detail = item.menu,
                    kind = vim.lsp.protocol.CompletionItemKind["Snippet"],
                })
            end
            done({ { items = items, isIncomplete = #items == 0 } })
        end,
        async = true,
    },
})
