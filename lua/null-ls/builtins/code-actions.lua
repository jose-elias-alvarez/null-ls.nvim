local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local api = vim.api

local CODE_ACTION = methods.internal.CODE_ACTION

local M = {}

M.gitsigns = h.make_builtin({
    name = "gitsigns",
    method = CODE_ACTION,
    filetypes = {},
    generator = {
        fn = function(params)
            local ok, gitsigns_actions = pcall(require("gitsigns").get_actions)
            if not ok or not gitsigns_actions then
                return
            end

            local name_to_title = function(name)
                return name:sub(1, 1):upper() .. name:gsub("_", " "):sub(2)
            end

            local actions = {}
            for name, action in pairs(gitsigns_actions) do
                table.insert(actions, {
                    title = name_to_title(name),
                    action = function()
                        api.nvim_buf_call(params.bufnr, action)
                    end,
                })
            end
            return actions
        end,
    },
})

M.proselint = h.make_builtin({
    name = "proselint",
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
                            api.nvim_buf_set_text(params.bufnr, row, col_beg, row, col_end, { d.replacements })
                        end,
                    })
                end
            end
            return actions
        end,
    },
    factory = h.generator_factory,
})

return M
