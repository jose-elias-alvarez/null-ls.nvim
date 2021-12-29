local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    method = CODE_ACTION,
    name = "toggle_line_comment",
    filetypes = {},
    generator = {
        fn = function(params)
            local bufnr = vim.api.nvim_get_current_buf()
            local commentstring = vim.api.nvim_buf_get_option(bufnr, "commentstring")
            local raw_commentstring = commentstring:gsub(vim.pesc("%s"), "")
            local line = params.content[params.row]

            if line:find(raw_commentstring, nil, true) then
                local uncommented = line:gsub(vim.pesc(raw_commentstring), "")
                return {
                    {
                        title = "Uncomment line",
                        action = function()
                            vim.api.nvim_buf_set_lines(bufnr, params.row - 1, params.row, false, {
                                uncommented,
                            })
                        end,
                    },
                }
            end

            return {
                {
                    title = "Comment line",
                    action = function()
                        vim.api.nvim_buf_set_lines(bufnr, params.row - 1, params.row, false, {
                            string.format(commentstring, line),
                        })
                    end,
                },
            }
        end,
    },
})
