local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "isort",
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "isort",
        args = {
            "--stdout",
            "--filename",
            "$FILENAME",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
