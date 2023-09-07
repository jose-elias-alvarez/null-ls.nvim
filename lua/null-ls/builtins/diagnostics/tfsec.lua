local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local function generic_issue(message)
    return {
        message = message,
        row = 1,
        source = "tfsec",
        severity = h.diagnostics.severities.error,
    }
end

return h.make_builtin({
    name = "tfsec",
    meta = {
        url = "https://github.com/aquasecurity/tfsec",
        description = "Security scanner for Terraform code",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "terraform", "tf", "terraform-vars" },
    generator_opts = {
        command = "tfsec",
        args = { "-s", "-f", "json", "$DIRNAME" },
        timeout = 30000,
        multiple_files = true,
        format = "raw",
        on_output = function(params, done)
            local issues = {}

            -- report any unexpected errors, such as partial file attempts
            if params.err then
                table.insert(issues, generic_issue(params.err))
            end

            -- if no output to parse, stop
            if not params.output then
                return done(issues)
            end

            local json_index, _ = params.output:find("{")

            -- if no json included, something went wrong and nothing to parse
            if not json_index then
                table.insert(issues, generic_issue(params.output))
                return done(issues)
            end

            local maybe_json_string = params.output:sub(json_index)

            local ok, decoded = pcall(vim.json.decode, maybe_json_string)

            -- decoding broke
            if not ok then
                return done(issues)
            end

            for _, result in ipairs(decoded.results or {}) do
                local err = {
                    message = result.description,
                    row = result.location.start_line,
                    end_row = result.location.end_line,
                    code = result.rule_id,
                    severity = h.diagnostics.severities.warning,
                    source = "tfsec",
                    filename = result.location.filename,
                }

                table.insert(issues, err)
            end

            done(issues)
        end,
    },
    factory = h.generator_factory,
})
