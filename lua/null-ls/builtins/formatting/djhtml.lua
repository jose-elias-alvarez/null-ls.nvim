local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "djhtml",
    meta = {
        url = "https://github.com/rtts/djhtml",
        description = "A pure-Python Django/Jinja template indenter without dependencies.",
    },
    method = FORMATTING,
    filetypes = { "django", "jinja.html", "htmldjango" },
    generator_opts = {
        command = "djhtml",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
