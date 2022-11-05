local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "typescript",
    meta = {
        url = "https://github.com/jose-elias-alvarez/typescript.nvim",
        description = "A Lua plugin, written in TypeScript, to write TypeScript (Lua optional).",
    },
    method = CODE_ACTION,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    generator = {
        fn = function(params)
            local ok, typescript = pcall(require, "typescript")
            if not ok or not typescript then
                return
            end

            local actions = {}
            for name, action in pairs(typescript.actions) do
                local cb = action
                table.insert(actions, {
                    title = name:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper),
                    action = function()
                        vim.api.nvim_buf_call(params.bufnr, cb)
                    end,
                })
            end
            return actions
        end,
    },
})
