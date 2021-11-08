local methods = require("null-ls.methods")

return {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(_, done)
            return done({ { text = "first" } })
        end,
        async = true,
    },
    filetypes = { "text" },
}
