local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "elm_format",
    meta = {
        url = "https://github.com/avh4/elm-format",
        description = "elm-format formats Elm source code according to a standard set of rules based on the official [Elm Style Guide](https://elm-lang.org/docs/style-guide).",
    },
    method = FORMATTING,
    filetypes = { "elm" },
    generator_opts = {
        command = "elm-format",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
