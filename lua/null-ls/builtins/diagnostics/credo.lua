local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

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
        format = "json_raw",
        to_stdin = true,
        from_stderr = true,
        on_output = function(params)
            local issues = {}
            if params.output and params.output.issues then
                for _, issue in ipairs(params.output.issues) do
                    local err = {
                        message = issue.message,
                        row = issue.line_no,
                        source = "credo",
                    }

                    --NOTE: priority is dynamic, ranges are from credo source
                    --could use `from_json` helper if mapped to same severity
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
            end

            --NOTE: by using stdin, partial files get sent that won't compile but
            --it can be reported for feedback in case any other errors occur as well
            if params.err then
                table.insert(issues, {
                    message = params.err,
                    row = 1,
                    source = "credo",
                })
            end

            return issues
        end,
    },
    factory = h.generator_factory,
})
