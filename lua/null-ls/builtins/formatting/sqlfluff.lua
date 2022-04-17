local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "sqlfluff",
    meta = {
        url = "https://github.com/sqlfluff/sqlfluff",
        description = "A SQL linter and auto-formatter for Humans",
        notes = {
            "SQLFluff needs a mandatory `--dialect` argument. Use `extra_args` to add yours. `extra_args` can also be a function to build more sophisticated logic.",
        },
        usage = [[
local sources = {
	null_ls.builtins.formatting.sqlfluff.with({
		extra_args = {"--dialect", "postgres"} -- change to your dialect
	})
}]],
    },
    method = FORMATTING,
    filetypes = { "sql" },
    generator_opts = {
        command = "sqlfluff",
        args = {
            "fix",
            "--disable_progress_bar",
            "-f",
            "-n",
            "-",
        },
        from_stdin = true,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
