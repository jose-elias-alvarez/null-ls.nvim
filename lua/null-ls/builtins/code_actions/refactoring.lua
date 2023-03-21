local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "refactoring",
    meta = {
        url = "https://github.com/ThePrimeagen/refactoring.nvim",
        description = "The Refactoring library based off the Refactoring book by Martin Fowler.",
        notes = {
            [[Requires visually selecting the code you want to refactor and calling `:'<,'>lua vim.lsp.buf.range_code_action()` (for the default handler) or `:'<,'>Telescope lsp_range_code_actions` (for Telescope).]],
        },
    },
    method = CODE_ACTION,
    filetypes = { "go", "javascript", "lua", "python", "typescript" },
    generator = {
        -- the plugin currently returns all refactors, regardless of context / availability
        -- so we ignore params
        fn = function(context)
            if context.lsp_params.range.start == context.lsp_params.range["end"] then
                return
            end

            local ok, refactors = pcall(require("refactoring").get_refactors)
            if not ok then
                return
            end

            local actions = {}
            for _, name in ipairs(refactors) do
                table.insert(actions, {
                    title = name,
                    action = function()
                        require("refactoring").refactor(name)
                    end,
                })
            end
            return actions
        end,
    },
})
