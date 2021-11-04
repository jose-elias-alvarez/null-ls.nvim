local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local utils = require("null-ls.utils")

local COMPLETION = methods.internal.COMPLETION

local M = {}

M.spell = h.make_builtin({
    method = COMPLETION,
    filetypes = {},
    name = "spell",
    runtime_condition = function(_)
        return vim.opt_local.spell:get()
    end,
    generator = {
        fn = function(params, done)
            local candidates = function(entries)
                local items = {}
                for k, v in ipairs(entries) do
                    items[k] = { label = v, kind = vim.lsp.protocol.CompletionItemKind["Text"] }
                end

                return items
            end

            done(candidates(vim.fn.spellsuggest(params.word_to_complete)))
        end,
        async = true,
        use_cache = true,
    },
})

return M
