local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "xmllint",
    method = FORMATTING,
    filetypes = { "xml" },
    generator_opts = {
        command = "xmllint",
        args = { "--format", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
