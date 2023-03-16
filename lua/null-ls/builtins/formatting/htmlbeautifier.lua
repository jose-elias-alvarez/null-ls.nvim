local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "htmlbeautifier",
    meta = {
        url = "https://github.com/threedaymonk/htmlbeautifier",
        description = "A normaliser/beautifier for HTML that also understands embedded Ruby. Ideal for tidying up Rails templates.",
    },
    method = FORMATTING,
    filetypes = { "eruby" },
    generator_opts = {
        command = "htmlbeautifier",
        args = {},
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
