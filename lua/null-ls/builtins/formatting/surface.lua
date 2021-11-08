local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "elixir", "surface" },
    generator_opts = {
        command = "mix",
        args = { "surface.format", "-" },
        format = "raw",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
