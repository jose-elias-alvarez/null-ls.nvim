local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "racket_fixw",
    meta = {
        url = "https://github.com/6cdh/racket-fixw",
        description = "A Racket formatter that add/remove some whitespaces but respects newline.",
        notes = { "Install with `raco pkg install fixw`" },
    },
    method = FORMATTING,
    filetypes = { "racket" },
    generator_opts = {
        command = "raco",
        args = { "fixw" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
