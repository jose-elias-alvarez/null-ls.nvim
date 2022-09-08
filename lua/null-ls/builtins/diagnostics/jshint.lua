local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "jshint",
    meta = {
        url = "https://github.com/jshint/jshint",
        description = "JSHint is a tool that helps to detect errors and potential problems in your JavaScript code.",
    },
    method = DIAGNOSTICS,
    filetypes = { "javascript" },
    generator_opts = {
        command = "jshint",
        args = {
            "--reporter",
            "unix",
            "--extract",
            "auto",
            "--filename",
            "$FILENAME",
            "-",
        },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(":(%d+):(%d+): (.*)$", { "row", "col", "message" }),
    },
    factory = h.generator_factory,
})
