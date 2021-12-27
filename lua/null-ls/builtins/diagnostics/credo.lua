local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local function generic_issue(message)
    return {
        message = message,
        row = 1,
        source = "credo",
    }
end

return h.make_builtin({
    name = "credo",
    method = DIAGNOSTICS,
    filetypes = { "elixir" },
    generator_opts = {
        command = "mix",
        --NOTE: search upwards to look for the credo config file
        cwd = function(params)
            local match = vim.fn.findfile(".credo.exs", vim.fn.fnamemodify(params.bufname, ":h") .. ";" .. params.root)

            if match then
                return vim.fn.fnamemodify(match, ":h")
            else
                return params.root
            end
        end,
        args = { "credo", "suggest", "--format", "json", "--read-from-stdin", "$FILENAME" },
        format = "raw",
        to_stdin = true,
        from_stderr = true,
        on_output = function(params, done)
            local issues = {}

            -- report any unexpected errors, such as partial file attempts
            if params.err then
                table.insert(issues, generic_issue(params.err))
            end

            -- if no output to parse, stop
            if not params.output then
                return issues
            end

            local json_index, _ = params.output:find("{")

            -- if no json included, something went wrong and nothing to parse
            if not json_index then
                table.insert(issues, generic_issue(params.output))

                return issues
            end

            local maybe_json_string = params.output:sub(json_index)

            local ok, decoded = pcall(vim.json.decode, maybe_json_string)

            -- decoding broke, so give up and return the original output
            if not ok then
                table.insert(issues, generic_issue(params.output))

                return issues
            end

            for _, issue in ipairs(decoded.issues or {}) do
                local err = {
                    message = issue.message,
                    row = issue.line_no,
                    source = "credo",
                }

                -- using the dynamic priority ranges from credo source
                if issue.priority >= 10 then
                    err.severity = h.diagnostics.severities.error
                elseif issue.priority >= 0 then
                    err.severity = h.diagnostics.severities.warning
                elseif issue.priority >= -10 then
                    err.severity = h.diagnostics.severities.information
                else
                    err.severity = h.diagnostics.severities.hint
                end

                if issue.column and issue.column ~= vim.NIL then
                    err.col = issue.column
                end

                if issue.column_end and issue.column_end ~= vim.NIL then
                    err.end_col = issue.column_end
                end

                table.insert(issues, err)
            end

            done(issues)
        end,
    },
    factory = h.generator_factory,
})
