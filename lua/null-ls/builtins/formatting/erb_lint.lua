local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "erb-lint",
    meta = {
        url = "https://github.com/Shopify/erb-lint",
        description = "Lint your ERB or HTML files",
    },
    method = FORMATTING,
    filetypes = { "eruby" },
    generator_opts = {
        command = "erblint",
        args = {
            "--autocorrect",
            "--stdin",
            "$FILENAME",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
