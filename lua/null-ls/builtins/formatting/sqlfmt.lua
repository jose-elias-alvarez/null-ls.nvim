local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

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
    METHOD = FORMATTING,
    filetypes = {
        "sql",
        "jinja",
    },
    generator_opts = {
        command = "sqlfmt",
        args = {},
        to_stdin = true,
        check_exit_code = { 0, 1 },
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern("dbt_project.yml")(params.bufnr)
        end),
    },
    factory = h.formatter_factory,
})
