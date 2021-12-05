local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "c", "cpp" },
    factory = h.generator_factory,
    generator_opts = {
        command = "gccdiag",
        args = {
            "--default-args",
            "-S -x $FILEEXT",
            "-i",
            "-fdiagnostics-color",
            "--",
            "$FILENAME",
        },
        to_stdin = false,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern(
            [[^([^:]+):(%d+):(%d+):%s+([^:]+):%s+(.*)$]],
            -- [[(%w+):(%d+):(%d+): (%w+): (.*)]],
            { "file", "row", "col", "severity", "message" },
            {
                severities = {
                    ["fatal error"] = h.diagnostics.severities.error,
                    ["error"] = h.diagnostics.severities.error,
                    ["note"] = h.diagnostics.severities.information,
                    ["warning"] = h.diagnostics.severities.warning,
                },
            }
        ),
    },
})
