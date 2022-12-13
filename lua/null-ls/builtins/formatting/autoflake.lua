local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "autoflake",
    meta = {
        url = "https://github.com/PyCQA/autoflake",
        description = "Removes unused imports and unused variables as reported by pyflakes",
    },
    method = { FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "autoflake",
        args = { "--stdin-display-name", "$FILENAME", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
