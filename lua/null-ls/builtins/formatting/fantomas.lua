local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fantomas",
    meta = {
        url = "https://github.com/fsprojects/fantomas",
        description = "FSharp source code formatter.",
    },
    method = FORMATTING,
    filetypes = { "fsharp" },
    generator_opts = {
        command = "fantomas",
        args = { "$FILENAME" },
        to_temp_file = true,
        from_temp_file = true,
    },
    factory = h.formatter_factory,
})
