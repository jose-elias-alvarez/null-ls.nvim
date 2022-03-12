local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local COMPLETION = methods.internal.COMPLETION

return h.make_builtin({
    name = "spell",
    meta = {
        description = "Spell suggestions completion source.",
    },
    method = COMPLETION,
    filetypes = {},
    generator = {
        fn = function(params, done)
            local get_candidates = function(entries)
                local items = {}
                for k, v in ipairs(entries) do
                    items[k] = { label = v, kind = vim.lsp.protocol.CompletionItemKind["Text"] }
                end

                return items
            end

            local candidates = get_candidates(vim.fn.spellsuggest(params.word_to_complete))
            done({ { items = candidates, isIncomplete = #candidates > 0 } })
        end,
        async = true,
    },
})
