local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

return helpers.make_builtin({
    name = "sqlfluff",
    meta = {
        url = "https://github.com/sqlfluff/sqlfluff",
        description = "A SQL linter and auto-formatter for Humans",
        notes = {
            "SQLFluff needs a mandatory `--dialect` argument. Use `extra_args` to add yours, or create a .sqlfluff file in the same directory as the SQL file to specify the dialect (see the sqlfluff docs for details). `extra_args` can also be a function to build more sophisticated logic.",
        },
        usage = [[
local sources = {
    null_ls.builtins.diagnostics.sqlfluff.with({
        extra_args = { "--dialect", "postgres" }, -- change to your dialect
    }),
}]],
    },
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "sql" },
    generator_opts = {
        command = "sqlfluff",
        args = {
            "lint",
            "--disable-progress-bar",
            "-f",
            "github-annotation",
            "-n",
            "$FILENAME",
        },
        from_stderr = false,
        to_stdin = false,
        to_temp_file = true,
        format = "json",
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = helpers.diagnostics.from_json({
            attributes = {
                row = "line",
                col = "start_column",
                end_col = "end_column",
                severity = "annotation_level",
                message = "message",
            },
            severities = {
                helpers.diagnostics.severities["information"],
                helpers.diagnostics.severities["warning"],
                helpers.diagnostics.severities["error"],
                helpers.diagnostics.severities["hint"],
            },
        }),
    },
    factory = helpers.generator_factory,
})
