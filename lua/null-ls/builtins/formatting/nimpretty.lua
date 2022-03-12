local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "nimpretty",
    meta = {
        url = "https://nim-lang.org/docs/tools.html",
        description = "nimpretty is a Nim source code beautifier, to format code according to the official style guide.",
    },
    method = FORMATTING,
    filetypes = { "nim" },
    generator_opts = {
        command = "nimpretty",
        args = { "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
