local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "smlfmt",
    meta = {
        url = "https://github.com/shwestrick/smlfmt",
        description = "A custom parser/auto-formatter for Standard ML",
    },
    method = FORMATTING,
    filetypes = { "sml" },
    generator_opts = {
        command = "smlfmt",
        args = {
            "--force",
            "$FILENAME",
        },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
