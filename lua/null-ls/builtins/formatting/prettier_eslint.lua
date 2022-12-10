local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "prettier_eslint",
    meta = {
        url = "https://github.com/prettier/prettier-eslint-cli",
        description = "CLI for [prettier-eslint](https://github.com/prettier/prettier-eslint)",
        notes = {
            "Known Issues: https://github.com/idahogurl/vs-code-prettier-eslint/issues/72#issuecomment-1247516987",
        },
    },
    method = { FORMATTING },
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
        command = "prettier-eslint",
        args = { "--stdin", "--stdin-filepath", "$FILENAME" },
        to_stdin = true,
        dynamic_command = cmd_resolver.from_node_modules(),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- supports both eslint and prettier config files
                -- https://prettier.io/docs/en/configuration.html
                ".prettierrc",
                ".prettierrc.json",
                ".prettierrc.yml",
                ".prettierrc.yaml",
                ".prettierrc.json5",
                ".prettierrc.js",
                ".prettierrc.cjs",
                ".prettier.config.js",
                ".prettier.config.cjs",
                ".prettierrc.toml",
                "eslint.config.js",
                -- https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats
                ".eslintrc",
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
