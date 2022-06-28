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
            'A file will be considered an AWS Cloudformation template if it contains a "Resources" or "AWSTemplateFormatVersion" key.',
            'To prevent cfn-lint running on all YAML and JSON files that contain a "Resources" key.',
            'The file must contain at least one AWS Cloudformation Resource Type, e.g "Type": "AWS::S3::Bucket"',
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

            -- matches the word AWSTemplateFormatVersion optionally surrounded by quotes, zero to many spaces, followed by a colon
            local template_format_version_pattern = '%s*"?AWSTemplateFormatVersion"?%s*:'

            -- matches the word Resources optionally surrounded by quotes, zero to many spaces, followed by a colon
            local resources_pattern = '"?Resources"?%s*:'

            -- This pattern matches the naming convention of an AWS cloudformation resource type "Type": "AWS::ProductIdentifier::ResourceType"
            -- matches the word Type optionally surrounded by quotes, zero to many spaces, followed by a colon,
            -- followed by AWS, 2 colons, 1 or more alphanumeric characters for the product identifier, separated by 2 colons,
            -- followed by one or more alaphanumeric characters for the resource type.
            local resource_type_pattern = '"?Type"?%s*:%s*"?\'?AWS::%w+::%w+"?\'?'

            local found_resources = false
            for _, line in ipairs(lines) do
                if line:match(template_format_version_pattern) then
                    return true
                end

                if line:match(resources_pattern) then
                    found_resources = true
                end

                -- file must contain both Resources as well as Type key which matches the aws resource type naming convention
                if found_resources and line:match(resource_type_pattern) then
                    return true
                end
            end

            return false
        end),
    },
    factory = h.generator_factory,
})
