local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "dart_format",
    meta = {
        url = "https://dart.dev/tools/dart-format",
        description = "Replace the whitespace in your program with formatting that follows Dart guidelines.",
    },
    method = FORMATTING,
    filetypes = { "dart" },
    generator_opts = {
        command = "dart",
        args = { "format" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
