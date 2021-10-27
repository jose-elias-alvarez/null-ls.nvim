local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "black",
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
