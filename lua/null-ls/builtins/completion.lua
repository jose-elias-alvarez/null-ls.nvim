local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local utils = require("null-ls.utils")

local COMPLETION = methods.internal.COMPLETION

local M = {}

M.tags = h.make_builtin({
    method = COMPLETION,
    filetypes = {},
    name = "tags",
    generator_opts = {
        runtime_condition = function(_)
            return #vim.fn.tagfiles() > 0
        end,
    },
    generator = {
        fn = function(params, done)
            -- Tags look up can be expensive.
            if #params.word_to_complete < 4 then
                done({ { items = {}, isIncomplete = false } })
                return
            end

            local tags = vim.fn.taglist(params.word_to_complete)
            if tags == 0 then
                done({ { items = {}, isIncomplete = false } })
                return
            end

            local words = {}
            local items = {}
            for _, tag in ipairs(tags) do
                table.insert(words, tag.name)
            end

            words = utils.table.uniq(words)
            for _, word in ipairs(words) do
                table.insert(items, {
                    label = word,
                    insertText = word,
                })
            end

            done({ { items = items, isIncomplete = #items == 0 } })
        end,
        async = true,
    },
})

M.spell = h.make_builtin({
    method = COMPLETION,
    filetypes = {},
    name = "spell",
    generator = {
        fn = function(params, done)
            local get_candidates = function(entries)
                local items = {}
                for k, v in ipairs(entries) do
                    items[k] = { label = v, kind = vim.lsp.protocol.CompletionItemKind["Text"] }
                end

                return items
            end

            local canditates = get_candidates(vim.fn.spellsuggest(params.word_to_complete))
            done({ { items = canditates, isIncomplete = #canditates } })
        end,
        async = true,
    },
})

return M
