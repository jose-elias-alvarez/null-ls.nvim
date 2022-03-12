local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local function generic_issue(message)
    return {
        message = message,
        row = 1,
        source = "protolint",
        severity = h.diagnostics.severities.error,
    }
end

return h.make_builtin({
    name = "protolint",
    meta = {
        url = "https://https//github.com/yoheimuta/protolint",
        description = "A pluggable linter and fixer to enforce Protocol Buffer style and conventions.",
    },
    method = DIAGNOSTICS,
    filetypes = { "proto" },
    generator_opts = {
        command = "protolint",
        args = { "--reporter", "json", "$FILENAME" },
        from_stderr = true,
        to_temp_file = true,
        format = "raw",
        check_exit_code = function(code)
            return code <= 1
        end,
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

            -- decoding broke, so give up and return the original output
            if not ok then
                table.insert(issues, generic_issue(params.output))

                return done(issues)
            end

            for _, issue in ipairs(decoded.lints or {}) do
                -- We're forced to use to_temp_file since Protolint dosen't accept stdin input.
                -- Due to the naming of temp files Protolint triggers 'FILE_NAMES_LOWER_SNAKE_CASE' error.
                -- As a dirty quickfix we simple skip this.
                if issue.rule ~= "FILE_NAMES_LOWER_SNAKE_CASE" then
                    local err = {
                        message = issue.message,
                        row = issue.line,
                        col = issue.column,
                        code = issue.rule,
                        severity = h.diagnostics.severities.warning,
                        source = "protolint",
                    }

                    table.insert(issues, err)
                end
            end

            done(issues)
        end,
    },
    factory = h.generator_factory,
})
