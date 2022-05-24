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
    meta = {
        url = "https://hexdocs.pm/credo",
        description = "Static analysis of `elixir` files for enforcing code consistency.",
        notes = {
            "Searches upwards from the buffer to the project root and tries to find the first `.credo.exs` file in case the project has nested `credo` configs.",
        },
    },
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
        on_output = function(params, done)
            local issues = {}

            -- credo is behaving in a bit of a tricky way:
            -- 1. if there are no elixir warnings, it will give its output
            --    on stderr, and stdout will be nil
            -- 2. if there are elixir warnings, it will report the elixir
            --    warnings on stderr, and its own output on stdout
            --
            -- also note.. "warnings".. this has been reproduced by doing a
            -- "mix new" project, then changing in mix.exs "def project" to add:
            -- compilers: Mix.compilers(),
            -- Then creating a file config/config.exs containing "use Mix.Config"
            local output = params.err -- assume there are no elixir warnings
            if params.output then
                -- output (stdout) is present! now we assume there are elixir
                -- warnings, and that therefore the credo output is on stdout...
                output = params.output
            end

            local json_index, _ = output:find("{")

            -- if no json included, something went wrong and nothing to parse
            if not json_index then
                table.insert(issues, generic_issue(output))

                return done(issues)
            end

            local maybe_json_string = output:sub(json_index)

            local ok, decoded = pcall(vim.json.decode, maybe_json_string)

            -- decoding broke, so give up and return the original output
            if not ok then
                table.insert(issues, generic_issue(output))

                return done(issues)
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
