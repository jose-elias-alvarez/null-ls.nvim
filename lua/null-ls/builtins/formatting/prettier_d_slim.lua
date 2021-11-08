local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "css",
        "scss",
        "less",
        "html",
        "json",
        "yaml",
        "markdown",
        "graphql",
    },
    generator_opts = {
        command = "prettier_d_slim",
        args = h.range_formatting_args_factory({ "--stdin", "--stdin-filepath", "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
