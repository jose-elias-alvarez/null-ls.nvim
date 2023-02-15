local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local severities = { 1, 2, 3, 4 }

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
            "spectral-report",
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
            for _, d in ipairs(params.output) do
                table.insert(diags, {
                    row = d.range.start.line,
                    col = d.range.start.character,
                    end_row = d.range["end"].line,
                    end_col = d.range["end"].character,
                    source = "Vacuum",
                    message = d.message,
                    severity = severities[d.severity + 1],
                    code = d.code,
                    path = d.path,
                })
            end
            return diags
        end,
    },
})
