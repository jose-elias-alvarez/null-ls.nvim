local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "protolint",
    method = { FORMATTING },
    filetypes = { "proto" },
    generator_opts = {
        command = "protolint",
        args = { "--fix", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
