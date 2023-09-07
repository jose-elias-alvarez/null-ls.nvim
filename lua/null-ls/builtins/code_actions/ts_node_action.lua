local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "ts_node_action",
    meta = {
        url = "https://github.com/CKolkey/ts-node-action",
        description = "A framework for running functions on Tree-sitter nodes, and updating the buffer with the result.",
    },
    method = CODE_ACTION,
    filetypes = {},
    can_run = function()
        local status, _ = pcall(require, "ts-node-action")
        return status
    end,
    generator = {
        fn = function()
            return require("ts-node-action").available_actions()
        end,
    },
})
