local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "yamlfmt",
    meta = {
        url = "https://github.com/google/yamlfmt",
        description = "yamlfmt is an extensible command line tool or library to format yaml files.",
    },
    method = FORMATTING,
    filetypes = { "yaml" },
    to_temp_file = true,
    generator_opts = { command = "yamlfmt", args = { "$FILENAME" } },
    factory = h.formatter_factory,
})
