local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint",
        args = { "--fix", "$FILENAME" },
        to_temp_file = true,
        ignore_stderr = true,
    },
    factory = h.formatter_factory,
})
