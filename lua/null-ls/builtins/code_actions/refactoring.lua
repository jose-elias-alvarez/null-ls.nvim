local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "refactoring",
    method = CODE_ACTION,
    filetypes = { "go", "javascript", "lua", "python", "typescript" },
    generator = {
        -- the plugin currently returns all refactors, regardless of context / availability
        -- so we ignore params
        fn = function(_)
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
