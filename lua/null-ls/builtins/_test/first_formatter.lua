local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    generator = {
        fn = function(_, done)
            vim.defer_fn(function()
                return done({ { text = "first" } })
            end, math.random(50))
        end,
        async = true,
    },
    filetypes = { "text" },
})
