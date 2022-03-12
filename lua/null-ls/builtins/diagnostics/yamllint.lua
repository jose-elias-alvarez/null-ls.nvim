local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "yamllint",
    meta = {
        url = "https://github.com/adrienverge/yamllint",
        description = "A linter for YAML files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml" },
    generator_opts = {
        command = "yamllint",
        to_stdin = true,
        args = { "--format", "parsable", "-" },
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): %[(%w+)%] (.*) %((.*)%)]],
            { "row", "col", "severity", "message", "code" },
            {
                severities = {
                    error = h.diagnostics.severities["error"],
                    warning = h.diagnostics.severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
