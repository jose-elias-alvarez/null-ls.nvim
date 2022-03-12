local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "terrafmt",
    meta = {
        url = "https://github.com/katbyte/terrafmt",
        description = "The terrafmt command formats `terraform` blocks embedded in Markdown files.",
    },
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "terrafmt",
        args = {
            "fmt",
            "$FILENAME",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
