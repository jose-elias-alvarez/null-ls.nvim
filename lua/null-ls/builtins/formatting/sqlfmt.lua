local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "sqlfmt",
    meta = {
        url = "https://sqlfmt.com/",
        description = "Formats your dbt SQL files so you don't have to",
        notes = {
            "Install sqlfmt with `pip install shandy-sqlfmt[jinjafmt]`",
        },
    },
    method = FORMATTING,
    filetypes = {
        "sql",
        "jinja",
    },
    generator_opts = {
        command = "sqlfmt",
        args = {
            "$FILENAME",
        },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
