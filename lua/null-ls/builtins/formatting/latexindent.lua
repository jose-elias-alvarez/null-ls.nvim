local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "latexindent",
    meta = {
        url = "https://github.com/cmhughes/latexindent.pl",
        description = "A perl script for formatting LaTeX files that is generally included in major TeX distributions.",
    },
    method = FORMATTING,
    filetypes = { "tex" },
    generator_opts = { command = "latexindent", args = { "-" }, to_stdin = true },
    factory = h.formatter_factory,
})
