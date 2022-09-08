local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "dprint",
    meta = {
        url = "https://dprint.dev/",
        description = "A pluggable and configurable code formatting platform written in Rust.",
        notes = {
            [[you need to install dprint to use this builtin and then run `dprint init` to initialize it in your project directory.]],
        },
    },
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "markdown",
        "toml",
        "rust",
        "roslyn",
    },
    generator_opts = {
        command = "dprint",
        args = {
            "fmt",
            "--stdin",
            "$FILENAME",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
