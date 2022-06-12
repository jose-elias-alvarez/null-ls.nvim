local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "blue",
    meta = {
        url = "https://github.com/grantjenks/blue",
        description = "Blue -- Some folks like black but I prefer blue.",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "blue",
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
