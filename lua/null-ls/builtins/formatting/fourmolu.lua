local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fourmolu",
    meta = {
        url = "https://hackage.haskell.org/package/fourmolu",
        description = "Fourmolu is a formatter for Haskell source code.",
    },
    method = FORMATTING,
    filetypes = { "haskell" },
    generator_opts = {
        command = "fourmolu",
        args = { "--stdin-input-file", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
