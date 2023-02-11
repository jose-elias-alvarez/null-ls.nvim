local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "textlint",
    meta = {
        url = "https://github.com/textlint/textlint",
        description = "The pluggable linting tool for text and Markdown.",
    },
    method = FORMATTING,
    filetypes = {"txt", "markdown"},
    generator_opts = {
        command = "textlint",
        args = { "--fix", "$FILENAME" },
        to_temp_file = true,
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
