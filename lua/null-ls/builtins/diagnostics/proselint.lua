local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "proselint",
    meta = {
        url = "https://github.com/amperser/proselint",
        description = "An English prose linter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "proselint",
        args = { "--json" },
        format = "json",
        to_stdin = true,
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = function(params)
            local diags = {}
            local sev = {
                error = 1,
                warning = 2,
                suggestion = 4,
            }
            for _, d in ipairs(params.output.data.errors) do
                table.insert(diags, {
                    row = d.line,
                    col = d.column,
                    end_col = d.column + d.extent - 1,
                    code = d.check,
                    message = d.message,
                    severity = sev[d.severity],
                })
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
