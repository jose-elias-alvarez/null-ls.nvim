local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "crates",
    meta = {
        url = "https://github.com/saecki/crates.nvim",
        description = "Code actions for editing `Cargo.toml` files.",
    },
    method = CODE_ACTION,
    filetypes = { "toml" },
    condition = function()
        return vim.fn.expand("%:t") == "Cargo.toml"
    end,
    generator = {
        fn = function(params)
            local ok, crates_actions = pcall(require, "crates.actions")
            if not ok or not crates_actions then
                return
            end

            local name_to_title = function(name)
                return name:sub(1, 1):upper() .. name:gsub("_", " "):sub(2)
            end

            local actions = {}
            for name, action in pairs(crates_actions.get_actions()) do
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
