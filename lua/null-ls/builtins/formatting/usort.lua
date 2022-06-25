local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "usort",
    meta = {
        url = "https://github.com/facebookexperimental/usort",
        description = "Safe, minimal import sorting for Python projects.",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "usort",
        args = {
            "format",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
