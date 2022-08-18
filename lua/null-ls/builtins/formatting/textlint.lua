local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "textlint",
    meta = {
        url = "https://github.com/textlint/textlint",
        description = "The pluggable linting tool for text and Markdown.",
    },
    method = FORMATTING,
    filetypes = {},
    generator_opts = {
        command = "textlint",
        args = { "--fix", "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
