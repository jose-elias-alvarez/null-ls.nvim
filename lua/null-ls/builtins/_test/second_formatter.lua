local methods = require("null-ls.methods")

return {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(params, done)
            return done({ { text = params.content[1] == "first" and "sequential" or "second" } })
        end,
        async = true,
    },
    filetypes = { "text" },
}
