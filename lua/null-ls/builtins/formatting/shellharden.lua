local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "sh",
    },
    generator_opts = {
        command = "shellharden",
        args = { "--transform", "$FILENAME" },
        to_stdin = false,
    },
    factory = h.formatter_factory,
})
