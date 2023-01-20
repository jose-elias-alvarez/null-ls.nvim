local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "prettier",
    meta = {
        url = "https://github.com/prettier/prettier",
        description = [[Prettier is an opinionated code formatter. It enforces a consistent style by parsing your code and re-printing it with its own rules that take the maximum line length into account, wrapping code when necessary.]],
        notes = {
            [[Supports more filetypes such as [Svelte](https://github.com/sveltejs/prettier-plugin-svelte) and [TOML](https://github.com/bd82/toml-tools/tree/master/packages/prettier-plugin-toml) via plugins. These filetypes are not enabled by default, but you can follow the instructions [here](BUILTIN_CONFIG.md#filetypes) to define your own list of filetypes.]],
            [[To increase speed, you may want to try [prettierd](https://github.com/fsouza/prettierd). You can also set up [eslint-plugin-prettier](https://github.com/prettier/eslint-plugin-prettier) and format via [eslint_d](https://github.com/mantoni/eslint_d.js/).]],
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
        command = "prettier",
        args = h.range_formatting_args_factory({
            "--stdin-filepath",
            "$FILENAME",
        }, "--range-start", "--range-end", { row_offset = -1, col_offset = -1 }),
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
