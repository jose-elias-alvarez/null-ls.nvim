local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "mypy",
        args = {
            "--hide-error-codes",
            "--hide-error-context",
            "--no-color-output",
            "--show-column-numbers",
            "--show-error-codes",
            "--no-error-summary",
            "--no-pretty",
            "--command",
            "$TEXT",
        },
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = function(...)
            local parser_result = h.diagnostics.from_pattern(
                "<string>:(%d+):(%d+): (%a+): (.*)  %[([%a-]+)%]", --
                { "row", "col", "severity", "message", "code" },
                {
                    severities = {
                        error = h.diagnostics.severities["error"],
                        warning = h.diagnostics.severities["warning"],
                        note = h.diagnostics.severities["information"],
                    },
                }
            )(...)

            if parser_result.code == "syntax" then
                return nil
            end

            return parser_result
        end,
    },
    factory = h.generator_factory,
})
