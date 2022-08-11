local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "stylish_haskell",
    meta = {
        url = "https://github.com/haskell/stylish-haskell",
        description = [[Format Haskell code]],
    },
    method = FORMATTING,
    filetypes = { "haskell" },
    generator_opts = {
        command = "stylish-haskell",
        args = {},
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
