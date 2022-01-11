local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "ansiblelint",
    method = DIAGNOSTICS,
    filetypes = { "yaml" },
    generator_opts = {
        command = "ansible-lint",
        to_stdin = true,
        ignore_stderr = true,
        args = { "--parseable-severity", "-q", "--nocolor", "$FILENAME" },
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = h.diagnostics.from_pattern(
            [[^[^:]+:(%d+): %[([%w-]+)%] %[([%w_]+)%] (.*)$]],
            { "row", "code", "severity", "message" },
            {
                severities = {
                    ["VERY_HIGH"] = h.diagnostics.severities.error,
                    ["HIGH"] = h.diagnostics.severities.error,
                    ["MEDIUM"] = h.diagnostics.severities.warning,
                    ["LOW"] = h.diagnostics.severities.warning,
                    ["VERY_LOW"] = h.diagnostics.severities.information,
                    ["INFO"] = h.diagnostics.severities.hint,
                },
            }
        ),
    },
    factory = h.generator_factory,
})
