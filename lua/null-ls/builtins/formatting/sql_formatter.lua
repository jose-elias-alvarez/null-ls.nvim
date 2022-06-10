local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "sql-formatter",
    meta = {
        url = "https://github.com/sql-formatter-org/sql-formatter",
        description = "A whitespace formatter for different query languages",
    },
    method = FORMATTING,
    filetypes = { "sql" },
    generator_opts = {
        command = "sql-formatter",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
