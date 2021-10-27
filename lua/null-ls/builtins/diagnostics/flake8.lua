local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "flake8",
        to_stdin = true,
        from_stderr = true,
        args = { "--format", "default", "--stdin-display-name", "$FILENAME", "-" },
        format = "line",
        check_exit_code = function(code)
            return code == 0 or code == 255
        end,
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): ((%u)%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            {
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                    F = h.diagnostics.severities["information"],
                    D = h.diagnostics.severities["information"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
