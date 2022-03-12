local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "joker",
    meta = {
        url = "https://github.com/candid82/joker",
        description = "joker is a small Clojure interpreter, linter and formatter written in Go.",
    },
    method = FORMATTING,
    filetypes = { "clj" },
    generator_opts = {
        command = "joker",
        args = { "--format", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
