local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "sqlformat",
    meta = {
        url = "https://manpages.ubuntu.com/manpages/xenial/man1/sqlformat.1.html",
        description = "The sqlformat command-line tool can reformat SQL files according to specified options.",
    },
    method = FORMATTING,
    filetypes = { "sql" },
    generator_opts = {
        command = "sqlformat",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
