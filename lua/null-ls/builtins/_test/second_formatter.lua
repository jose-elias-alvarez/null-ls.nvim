local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    generator = {
        fn = function(params, done)
            local timeout = math.random(50)
            vim.defer_fn(function()
                return done({ { text = params.content[1] == "first" and "sequential" or "second" } })
            end, timeout)
        end,
        async = true,
    },
    filetypes = { "text" },
})
