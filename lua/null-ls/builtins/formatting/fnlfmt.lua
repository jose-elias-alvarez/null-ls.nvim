local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fnlfmt",
    meta = {
        url = "https://git.sr.ht/~technomancy/fnlfmt",
        description = "fnlfmt is a Fennel code formatter which follows established Lisp conventions when determining how to format a given piece of code.",
    },
    method = FORMATTING,
    filetypes = { "fennel", "fnl" },
    generator_opts = {
        command = "fnlfmt",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
