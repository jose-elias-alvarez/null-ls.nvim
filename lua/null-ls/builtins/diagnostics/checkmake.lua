local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "checkmake",
    meta = {
        url = "https://github.com/mrtazz/checkmake",
        description = "`make` linter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "make" },
    generator_opts = {
        command = "checkmake",
        args = {
            "--format='{{.LineNumber}}:{{.Rule}}:{{.Violation}}\n'",
            "$FILENAME",
        },
        to_stdin = false,
        from_stderr = false,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code >= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(%d+):(%w+):(.+)]],
                groups = { "row", "code", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
