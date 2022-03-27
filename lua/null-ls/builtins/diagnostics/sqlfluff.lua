local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

return helpers.make_builtin({
    name = "sqlfluff",
    meta = {
        url = "https://github.com/sqlfluff/sqlfluff",
        description = "A SQL linter and auto-formatter for Humans",
    },
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "sql" },
    generator_opts = {
        command = "sqlfluff",
        args = {
            "lint",
            "-f",
            "github-annotation",
            "-n",
            "--disable_progress_bar",
            "-",
        },
        from_stderr = true,
        to_stdin = true,
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
