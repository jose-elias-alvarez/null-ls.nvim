local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ktlint",
    meta = {
        url = "https://ktlint.github.io/",
        description = "An anti-bikeshedding Kotlin linter with built-in formatter.",
    },
    method = FORMATTING,
    filetypes = { "kotlin" },
    generator_opts = {
        command = "ktlint",
        args = {
            "--format",
            "--stdin",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
