local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "astyle",
    method = FORMATTING,
    filetypes = { "arduino", "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "astyle",
        args = {
            "--quiet",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
