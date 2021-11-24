local methods = require("null-ls.methods")

return {
    method = methods.internal.PROJECT_DIAGNOSTICS,
    filetypes = { "text" },
    generator = {
        fn = function(params)
            return {
                { message = "something is wrong with this file", filename = params.bufname },
            }
        end,
    },
}
