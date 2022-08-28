local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

return helpers.make_builtin({
    name = "bandit",
    meta = {
        url = "https://github.com/PyCQA/bandit",
        description = "Bandit is a tool designed to find common security issues in Python code.",
    },
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "python" },
    generator = helpers.generator_factory({
        command = "bandit",
        name = "bandit",
        args = {
            "--format",
            "json",
            "-",
        },
        to_stdin = true,
        from_stderr = false,
        ignore_stderr = true,
        format = "json",
        check_exit_code = { 0, 1 },
        on_output = function(params)
            local parse = helpers.diagnostics.from_json({
                attributes = {
                    row = "line_number",
                    col = "col_offset",
                    code = "test_id",
                    message = "issue_text",
                    severity = "issue_severity",
                },
                offsets = { col = 1 },
                severities = {
                    HIGH = helpers.diagnostics.severities["error"],
                    MEDIUM = helpers.diagnostics.severities["warning"],
                    LOW = helpers.diagnostics.severities["information"],
                },
            })

            if params.output then
                params.output = params.output.results
                return parse(params)
            end

            return {}
        end,
    }),
})
