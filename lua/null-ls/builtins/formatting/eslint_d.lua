local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

-- eslint_d has a --fix-to-stdout flag, so we can avoid parsing json
return h.make_builtin({
    name = "eslint_d",
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    generator_opts = {
        command = "eslint_d",
        args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
    meta = {
        url = "https://github.com/mantoni/eslint_d.js/",
        description = "Makes eslint the fastest linter on the planet.",
    },
})
