local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "nim" },
    generator_opts = {
        command = "nimpretty",
        args = { "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
