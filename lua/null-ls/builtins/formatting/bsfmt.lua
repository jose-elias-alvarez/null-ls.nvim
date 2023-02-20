local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "bsfmt",
    meta = {
        url = "https://github.com/rokucommunity/brighterscript-formatter",
        description = "A code formatter for BrightScript and BrighterScript.",
    },
    method = FORMATTING,
    filetypes = { "brs" },
    generator_opts = {
        command = "bsfmt",
        args = { "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
