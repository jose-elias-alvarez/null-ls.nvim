local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "buf_format",
    meta = {
        url = "https://github.com/bufbuild/buf",
        description = "A new way of working with Protocol Buffers.",
    },
    method = FORMATTING,
    to_stdin = true,
    filetypes = { "proto" },
    generator_opts = {
        command = "buf",
        args = {
            "format",
            "--stdin",
            "$FILENAME",
        },
    },
    factory = h.formatter_factory,
})
