local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "prettier_standard",
    meta = {
        url = "https://github.com/sheerun/prettier-standard",
        description = "Formats with Prettier and lints with ESLint+Standard! (✿◠‿◠)",
    },
    method = FORMATTING,
    filetypes = { "javascript", "javascriptreact" },
    generator_opts = {
        command = "prettier-standard",
        args = { "--stdin" },
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
