local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "just",
    meta = {
        url = "https://just.systems/",
        description = [[Format your Justfile]],
    },
    method = FORMATTING,
    filetypes = { "just" },
    generator_opts = {
        command = "just",
        args = {
            "--fmt",
            "--unstable",
            "-f",
            "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
        from_temp_file = true,
    },
    factory = h.formatter_factory,
})
