local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "purs_tidy",
    meta = {
        url = "https://github.com/natefaubion/purescript-tidy",
        description = "A syntax tidy-upper (formatter) for PureScript.",
        notes = {
            "For installation, use npm: npm install -g purs-tidy",
        },
    },
    method = FORMATTING,
    filetypes = { "purescript" },
    generator_opts = {
        command = "purs-tidy",
        args = { "format" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
