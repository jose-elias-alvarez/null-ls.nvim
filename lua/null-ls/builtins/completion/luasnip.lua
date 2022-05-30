local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local COMPLETION = methods.internal.COMPLETION

local function get_documentation(snip, data)
    local header = (snip.name or "") .. " _ `[" .. data.filetype .. "]`\n"
    local docstring = { "", "```" .. vim.bo.filetype, snip:get_docstring(), "```" }
    local documentation = { header .. "---", (snip.dscr or ""), docstring }
    documentation = require("vim.lsp.util").convert_input_to_markdown_lines(documentation)
    documentation = table.concat(documentation, "\n")
    return documentation
end

return h.make_builtin({
    name = "luasnip",
    meta = {
        url = "https://github.com/L3MON4D3/LuaSnip",
        description = "Snippet engine for Neovim, written in Lua.",
        notes = {
            "Registering this source will show available snippets in the completion list, but luasnip is in charge of expanding them. Consult [luasnip's documentation](https://github.com/L3MON4D3/LuaSnip#keymaps) to set up keymaps for expansion and jumping.",
        },
    },
    method = COMPLETION,
    filetypes = {},
    generator = {
        fn = function(params, done)
            local filetypes = require("luasnip.util.util").get_snippet_filetypes()
            local items = {}

            for i = 1, #filetypes do
                local ft = filetypes[i]
                local ft_table = require("luasnip").get_snippets(ft)
                if ft_table then
                    for j, snip in pairs(ft_table) do
                        local data = {
                            type = "luasnip",
                            filetype = ft,
                            ft_indx = j,
                            show_condition = snip.show_condition,
                        }
                        if not snip.hidden then
                            items[#items + 1] = {
                                word = snip.trigger,
                                label = snip.trigger,
                                detail = snip.description,
                                kind = vim.lsp.protocol.CompletionItemKind.Snippet,
                                data = data,
                                documentation = {
                                    value = get_documentation(snip, data),
                                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                                },
                            }
                        end
                    end
                end
            end
            local line_to_cursor = require("luasnip.util.util").get_current_line_to_cursor()
            done({
                {
                    items = vim.tbl_filter(function(item)
                        return vim.startswith(item.word, params.word_to_complete)
                            and item.data.show_condition(line_to_cursor)
                    end, items),
                    isIncomplete = #items == 0,
                },
            })
        end,
        async = true,
    },
})
