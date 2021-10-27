local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "asm" },
    generator_opts = {
        command = "asmfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
