local u = require("null-ls.utils")
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

local M = {}

M.gitsigns = h.make_builtin({
    method = CODE_ACTION,
    filetypes = { "*" },
    generator = {
        fn = function()
            local name_to_title = function(name)
                return u.string.to_start_case(string.gsub(name, "_", " "))
            end

            local actions = {}
            for name, action in pairs(require("gitsigns").get_actions()) do
                table.insert(actions, { title = name_to_title(name), action = action })
            end
            return actions
        end,
    },
})

return M
