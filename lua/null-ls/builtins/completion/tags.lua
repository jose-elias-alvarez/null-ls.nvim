local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local utils = require("null-ls.utils")

local COMPLETION = methods.internal.COMPLETION

return h.make_builtin({
    name = "tags",
    meta = {
        description = "Tags completion source.",
    },
    method = COMPLETION,
    filetypes = {},
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
