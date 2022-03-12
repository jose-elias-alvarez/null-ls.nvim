local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "markdownlint",
    meta = {
        url = "https://github.com/igorshubovych/markdownlint-cli",
        description = "A Node.js style checker and lint tool for Markdown/CommonMark files.",
        notes = {
            "Can fix some (but not all!) markdownlint issues. If possible, use [Prettier](https://github.com/prettier/prettier), which can also fix Markdown files.",
        },
    },
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint",
        args = { "--fix", "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
