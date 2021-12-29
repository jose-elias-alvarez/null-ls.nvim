local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local HOVER = methods.internal.HOVER

return h.make_builtin({
    method = HOVER,
    generator = {
        fn = function()
            return { "test" }
        end,
    },
    filetypes = { "text" },
})
