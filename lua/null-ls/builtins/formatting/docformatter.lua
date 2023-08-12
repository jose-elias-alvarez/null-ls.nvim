local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "docformatter",
    meta = {
        url = "https://github.com/PyCQA/docformatter/",
        description = "Python formatter complaint with the PEP 257 standard",
    },
    method = { FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "docformatter",
        -- black compatibility added by default because 74 cols is very restrictive
        -- in modern times
        args = { "--black", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
