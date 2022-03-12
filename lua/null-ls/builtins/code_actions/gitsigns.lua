local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "gitsigns",
    meta = {
        url = "https://github.com/lewis6991/gitsigns.nvim",
        description = "Injects code actions for Git operations at the current cursor position (stage / preview / reset hunks, blame, etc.).",
    },
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
                        vim.api.nvim_buf_call(params.bufnr, action)
                    end,
                })
            end
            return actions
        end,
    },
})
