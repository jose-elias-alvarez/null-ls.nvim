local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fprettify",
    meta = {
        url = "https://github.com/pseewald/fprettify",
        description = "fprettify is an auto-formatter for modern Fortran code that imposes strict whitespace formatting, written in Python.",
    },
    method = FORMATTING,
    filetypes = { "fortran" },
    generator_opts = {
        command = "fprettify",
        args = {
            "--silent",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
