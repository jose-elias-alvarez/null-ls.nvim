local null_ls = require("null-ls")
local h = require("null-ls.helpers")

return h.make_builtin({
    name = "phpmd",
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "phpmd",
        args = {
            "--ignore-violations-on-exit",
            "-", -- process stdin
            "json",
            -- 'phpmd.xml',
        },
        format = "json_raw",
        to_stdin = true,
        from_stderr = false,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local parser = h.diagnostics.from_json({
                attributes = {
                    message = "description",
                    severity = "priority",
                    row = "beginLine",
                    end_row = "endLine",
                    code = "rule",
                },
                severities = {
                    h.diagnostics.severities["error"],
                    h.diagnostics.severities["warning"],
                    h.diagnostics.severities["information"],
                    h.diagnostics.severities["hint"],
                },
            })
            params.violations = params.output
                    and params.output.files
                    and params.output.files[1]
                    and params.output.files[1].violations
                or {}

            return parser({ output = params.violations })
        end,
    },
    factory = h.generator_factory,
})
