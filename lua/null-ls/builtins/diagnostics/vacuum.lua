local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local severities = { error = 1, warn = 2, info = 3, hint = 4 }

return h.make_builtin({
    name = "vacuum",
    meta = {
        url = "https://quobix.com/vacuum",
        description = "The world’s fastest and most scalable OpenAPI linter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml", "json" },
    generator_opts = {
        command = "vacuum",
        args = {
            "report",
            "--stdin",
            "--stdout",
        },
        format = "json",
        to_stdin = true,
        ignore_stderr = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local diags = {}
            if params.output.resultSet.results == vim.NIL then
                return diags
            end

            for _, d in ipairs(params.output.resultSet.results) do
                table.insert(diags, {
                    row = d.range.start.line,
                    col = d.range.start.character,
                    end_row = d.range["end"].line,
                    end_col = d.range["end"].character,
                    source = "Vacuum",
                    message = d.message,
                    severity = severities[d.ruleSeverity],
                    code = d.ruleId,
                    path = d.path,
                })
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
