local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cfn-lint",
    meta = {
        url = "https://github.com/aws-cloudformation/cfn-lint",
        description = "Validate AWS CloudFormation yaml/json templates against the AWS CloudFormation Resource Specification",
        notes = {
            "Once a supported file type is opened null-ls will try and determine if the file looks like an AWS Cloudformation template.",
            'A file will be considered an AWS Cloudformation template if it contains "Resources" or "AWSTemplateFormatVersion".',
            "This check will run only once when entering the buffer.",
            'This means if "Resources" or "AWSTemplateFormatVersion" is added to a file after this check is run, the cfn-lint diagnostics will not be generated.',
            "To fix this you must restart Neovim.",
        },
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
        runtime_condition = h.cache.by_bufnr(function(params)
            -- check if file looks like a cloudformation template
            local lines = vim.api.nvim_buf_get_lines(params.bufnr, 0, -1, false)
            for _, line in ipairs(lines) do
                if line:match("Resources") or line:match("AWSTemplateFormatVersion") then
                    return true
                end
            end
            return false
        end),
    },
    factory = h.generator_factory,
})
