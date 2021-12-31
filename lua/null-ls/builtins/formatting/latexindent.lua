local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "latexindent",
    method = FORMATTING,
    filetypes = { "tex" },
    generator_opts = { command = "latexindent", args = { "-" }, to_stdin = true },
    factory = h.formatter_factory,
})
