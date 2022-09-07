local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "prettierd",
    meta = {
        url = "https://github.com/fsouza/prettierd",
        description = "prettier, as a daemon, for ludicrous formatting speed.",
    },
    method = FORMATTING,
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
        command = "prettierd",
        args = { "$FILENAME" },
        dynamic_command = cmd_resolver.from_node_modules(),
        to_stdin = true,
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
                ".prettier.config.js",
                ".prettier.config.cjs",
                ".prettierrc.toml",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
