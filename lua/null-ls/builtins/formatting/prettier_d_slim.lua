local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "prettier_d_slim",
    meta = {
        url = "https://github.com/mikew/prettier_d_slim",
        description = "Makes prettier fast.",
        notes = {
            "May not work on some filetypes.",
            "`prettierd` is more stable and recommended.",
        },
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "css",
        "scss",
        "less",
        "html",
        "json",
        "jsonc",
        "yaml",
        "markdown",
        "graphql",
        "handlebars",
    },
    generator_opts = {
        command = "prettier_d_slim",
        args = h.range_formatting_args_factory(
            { "--stdin", "--stdin-filepath", "$FILENAME" },
            "--range-start",
            "--range-end",
            { row_offset = -1, col_offset = -1 }
        ),
        to_stdin = true,
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.formatter_factory,
})
