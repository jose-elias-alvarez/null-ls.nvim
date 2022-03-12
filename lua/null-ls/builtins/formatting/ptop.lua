local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ptop",
    meta = {
        url = "https://www.freepascal.org/tools/ptop.html",
        description = "The FPC Pascal configurable source beautifier. Name means 'Pascal-TO-Pascal'.",
    },
    method = FORMATTING,
    filetypes = { "pascal", "delphi" },
    generator_opts = {
        command = "ptop",
        args = { "$FILENAME", "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
