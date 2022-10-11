local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

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
        "markdown.mdx",
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
        dynamic_command = cmd_resolver.from_node_modules(),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://prettier.io/docs/en/configuration.html
                ".prettierrc",
                ".prettierrc.json",
                ".prettierrc.yml",
                ".prettierrc.yaml",
                ".prettierrc.json5",
                ".prettierrc.js",
                ".prettierrc.cjs",
                ".prettierrc.toml",
                "prettier.config.js",
                "prettier.config.cjs",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
