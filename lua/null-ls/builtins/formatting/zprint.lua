local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "zprint",
    meta = {
        url = "https://github.com/kkinnear/zprint",
        description = "Beautifully format Clojure and Clojurescript source code and s-expressions.",
        notes = { "Requires that `zprint` is executable and on $PATH." },
    },
    method = FORMATTING,
    filetypes = { "clojure" },
    generator_opts = {
        command = "zprint",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
