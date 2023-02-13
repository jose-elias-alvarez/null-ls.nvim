local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "textlint",
    meta = {
        url = "https://github.com/textlint/textlint",
        description = "The pluggable linting tool for text and Markdown.",
    },
    method = FORMATTING,
    filetypes = { "txt", "markdown" },
    generator_opts = {
        command = "textlint",
        args = { "--fix", "$FILENAME" },
        to_temp_file = true,
        dynamic_command = cmd_resolver.from_node_modules(),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://textlint.github.io/docs/configuring.html
                ".textlintrc",
                ".textlintrc.js",
                ".textlintrc.json",
                ".textlintrc.yml",
                ".textlintrc.yaml",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
