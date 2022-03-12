local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "json_tool",
    meta = {
        url = "https://docs.python.org/3/library/json.html#module-json.tool",
        description = "Provides a simple command line interface to validate and pretty-print JSON objects.",
    },
    method = FORMATTING,
    filetypes = { "json" },
    generator_opts = {
        command = "python",
        args = { "-m", "json.tool" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
