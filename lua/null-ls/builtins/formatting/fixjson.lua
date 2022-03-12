local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fixjson",
    meta = {
        url = "https://github.com/rhysd/fixjson",
        description = "A JSON file fixer/formatter for humans using (relaxed) JSON5.",
    },
    method = FORMATTING,
    filetypes = { "json" },
    generator_opts = {
        command = "fixjson",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
