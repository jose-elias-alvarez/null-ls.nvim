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
    to_temp_file = true,
    from_temp_file = true,
    filetypes = { "proto" },
    generator_opts = {
        command = "buf",
        args = {
            "format",
            "-w",
            "$FILENAME",
        },
    },
    factory = h.formatter_factory,
})
