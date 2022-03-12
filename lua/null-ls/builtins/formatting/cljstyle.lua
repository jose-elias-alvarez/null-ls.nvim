local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "cljstyle",
    meta = {
        url = "https://github.com/greglook/cljstyle",
        description = "Formatter for Clojure code.",
    },
    method = FORMATTING,
    filetypes = { "clojure" },
    generator_opts = {
        command = "cljstyle",
        args = { "pipe" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
