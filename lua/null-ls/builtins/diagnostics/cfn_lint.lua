local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cfn-lint",
    meta = {
        url = "https://github.com/aws-cloudformation/cfn-lint",
        description = "Validate AWS CloudFormation yaml/json templates against the AWS CloudFormation Resource Specification",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml", "json" },
    generator_opts = {
        command = "cfn-lint",
        args = { "--format", "parseable", "-" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+):(%d+):(%d+):(([IEW]).*):(.*)]],
            { "row", "col", "end_row", "end_col", "code", "severity", "message" },
            {
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                    I = h.diagnostics.severities["information"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
