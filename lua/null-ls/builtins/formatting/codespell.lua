local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "codespell",
    meta = {
        url = "https://github.com/codespell-project/codespell",
        description = "Fix common misspellings in text files.",
    },
    method = FORMATTING,
    filetypes = {},
    generator_opts = {
        command = "codespell",
        args = { "--write-changes", "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
