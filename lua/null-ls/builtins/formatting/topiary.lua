local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "topiary",
    meta = {
        url = "https://github.com/tweag/topiary",
        description = "A uniform formatter for simple languages",
    },
    method = FORMATTING,
    filetypes = { "ncl", "nickel" },
    generator_opts = {
        command = "topiary",
        args = {
            "-i", -- format file in place when from_temp_file = true
            "-f",
            "$FILENAME",
        },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
