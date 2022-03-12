local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "pg_format",
    meta = {
        url = "https://github.com/darold/pgFormatter",
        description = "PostgreSQL SQL syntax beautifier",
    },
    method = FORMATTING,
    filetypes = { "sql", "pgsql" },
    generator_opts = {
        command = "pg_format",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
