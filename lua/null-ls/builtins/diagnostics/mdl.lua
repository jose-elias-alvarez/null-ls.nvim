local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "mdl",
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "mdl",
        args = { "--json" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line",
                code = "rule",
                message = "description",
            },
            diagnostic = {
                severity = h.diagnostics.severities.warning,
            },
        }),
    },
    factory = h.generator_factory,
})
