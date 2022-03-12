local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "raco_fmt",
    meta = {
        url = "https://docs.racket-lang.org/fmt/",
        description = "The fmt package provides an extensible tool to format Racket code, using an expressive pretty printer library to compute the optimal layout.",
        notes = {
            "Requires Racket 8.0 or later",
            "Install with `raco pkg install fmt`",
        },
    },
    method = FORMATTING,
    filetypes = { "racket" },
    generator_opts = {
        command = "raco",
        args = { "fmt" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
