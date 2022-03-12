local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "proselint",
    meta = {
        url = "https://github.com/amperser/proselint",
        description = "An English prose linter. Can fix some issues via code actions.",
    },
    method = CODE_ACTION,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "proselint",
        args = { "--json" },
        format = "json",
        to_stdin = true,
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = function(params)
            local actions = {}
            for _, d in ipairs(params.output.data.errors) do
                if d.replacements ~= vim.NIL and params.row == d.line then
                    local row = d.line - 1
                    local col_beg = d.column - 1
                    local col_end = d.column + d.extent - 2
                    table.insert(actions, {
                        title = d.message,
                        action = function()
                            vim.api.nvim_buf_set_text(params.bufnr, row, col_beg, row, col_end, { d.replacements })
                        end,
                    })
                end
            end
            return actions
        end,
    },
    factory = h.generator_factory,
})
