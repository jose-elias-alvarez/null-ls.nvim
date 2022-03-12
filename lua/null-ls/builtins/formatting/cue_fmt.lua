local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "cue_fmt",
    meta = {
        url = "https://cuelang.org/",
        description = "A CUE language formatter.",
    },
    method = FORMATTING,
    filetypes = { "cue" },
    generator_opts = {
        command = "cue",
        args = {
            "fmt",
            "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
