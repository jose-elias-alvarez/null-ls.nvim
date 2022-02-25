local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "uncrustify",
    method = FORMATTING,
    filetypes = { "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "uncrustify",
        args = function(params)
            return { "-q", "-l", params.ft:upper() }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
