local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "raco_fmt",
    method = FORMATTING,
    filetypes = { "racket" },
    generator_opts = {
        command = "raco",
        args = { "fmt", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
