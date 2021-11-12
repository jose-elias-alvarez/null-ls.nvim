local methods = require("null-ls.methods")

return {
    method = methods.internal.HOVER,
    generator = {
        fn = function()
            return { "test" }
        end,
    },
    filetypes = { "text" },
}
