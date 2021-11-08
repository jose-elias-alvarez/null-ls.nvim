local methods = require("null-ls.methods")

return {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(_, done)
            return done({ { text = "runtime" } })
        end,
        opts = {
            runtime_condition = function(_)
                return false
            end,
        },
        async = true,
    },
    filetypes = { "text" },
}
