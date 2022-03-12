local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "cabal_fmt",
    meta = {
        url = "https://hackage.haskell.org/package/cabal-fmt",
        description = "Format .cabal files preserving the original field ordering, and comments.",
    },
    method = FORMATTING,
    filetypes = { "cabal" },
    generator_opts = {
        command = "cabal-fmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
