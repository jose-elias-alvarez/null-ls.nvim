local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "pyink",
    meta = {
        url = "https://github.com/google/pyink",
        description = "The Google Python code formatter",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "pyink",
        args = {
            "--stdin-filename",
            "$FILENAME",
            "--quiet",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
