local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "rpmspec",
    meta = {
        url = "https://rpm.org/",
        description = "Command line tool to parse RPM spec files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "spec" },
    generator_opts = {
        command = "rpmspec",
        args = {
            "-P",
            "$FILENAME",
        },
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        format = "line",
        check_exit_code = { 0, 1 },
        on_output = h.diagnostics.from_patterns({
            -- error
            {
                pattern = [[(%w+): (.*): line (%d+): (.*)]],
                groups = { "severity", "filename", "row", "message" },
            },
            -- warning
            {
                pattern = [[(%w+): (.*) in line (%d+):]],
                groups = { "severity", "message", "row" },
            },
        }),
    },
    factory = h.generator_factory,
})
