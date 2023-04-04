local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local severities = { 1, 2, 3, 4 }

return h.make_builtin({
    name = "spectral",
    meta = {
        url = "https://github.com/stoplightio/spectral",
        description = "A flexible JSON/YAML linter for creating automated style guides, with baked in support for OpenAPI v3.1, v3.0, and v2.0.",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml", "json" },
    generator_opts = {
        command = "spectral",
        args = {
            "lint",
            "--stdin-filepath",
            "$FILENAME",
            "-f",
            "json",
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
                    row = d.range.start.line + 1,
                    col = d.range.start.character,
                    end_row = d.range["end"].line + 1,
                    end_col = d.range["end"].character,
                    source = "Spectral",
                    message = d.message,
                    severity = severities[d.severity + 1],
                    code = d.code,
                    path = d.path,
                })
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
