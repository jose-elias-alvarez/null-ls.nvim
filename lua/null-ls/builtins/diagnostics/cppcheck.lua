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
        to_stdin = true,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern([[(%d+):(%d+): (%w+): (.*)]], { "row", "col", "severity", "message" }, {
            severities = {
                note = h.diagnostics.severities["information"],
                style = h.diagnostics.severities["hint"],
                performance = h.diagnostics.severities["warning"],
                portability = h.diagnostics.severities["information"],
            },
        }),
    },
    factory = h.generator_factory,
})
