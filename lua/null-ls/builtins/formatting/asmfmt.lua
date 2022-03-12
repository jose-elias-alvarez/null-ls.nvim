local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "asmfmt",
    meta = {
        url = "https://github.com/klauspost/asmfmt",
        description = "Format your assembler code in a similar way that `gofmt` formats your `go` code.",
    },
    method = FORMATTING,
    filetypes = { "asm" },
    generator_opts = {
        command = "asmfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
