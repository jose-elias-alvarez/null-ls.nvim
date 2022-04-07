local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cppcheck",
    meta = {
        url = "https://github.com/danmar/cppcheck",
        description = "A tool for fast static analysis of C/C++ code.",
    },
    method = DIAGNOSTICS,
    filetypes = { "cpp", "c" },
    generator_opts = {
        command = "cppcheck",
        args = {
            "--enable=warning,style,performance,portability",
            "--template=gcc",
            "$FILENAME",
        },
        format = "line",
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_pattern([[(%d+):(%d+): (%w+): (.*)]], { "row", "col", "severity", "message" }, {
            severities = {
                note = h.diagnostics.severities["information"],
                style = h.diagnostics.severities["hint"],
                performance = h.diagnostics.severities["warning"],
                portability = h.diagnostics.severities["information"],
            },
        }),
        check_exit_code = function(code)
            return code >= 1
        end,
    },
    factory = h.generator_factory,
})
