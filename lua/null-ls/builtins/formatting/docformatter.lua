local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "docformatter",
    meta = {
        url = "https://github.com/PyCQA/docformatter",
        description = "Formats Python docstrings to follow PEP 257",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "docformatter",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
