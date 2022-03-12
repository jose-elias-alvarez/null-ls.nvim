local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "surface",
    meta = {
        url = "https://hexdocs.pm/surface_formatter/readme.html",
        description = "A code formatter for Surface, the server-side rendering component library for Phoenix.",
    },
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
