local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "shfmt",
    meta = {
        url = "https://github.com/mvdan/sh",
        description = "A shell parser, formatter, and interpreter with `bash` support.",
    },
    method = FORMATTING,
    filetypes = { "sh" },
    generator_opts = {
        command = "shfmt",
        args = { "-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
