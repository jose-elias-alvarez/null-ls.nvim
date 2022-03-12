local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "nixfmt",
    meta = {
        url = "https://github.com/serokell/nixfmt",
        description = "nixfmt is a formatter for Nix code, intended to apply a uniform style.",
    },
    method = FORMATTING,
    filetypes = { "nix" },
    generator_opts = {
        command = "nixfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
