local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cpplint",
    meta = {
        url = "https://github.com/cpplint/cpplint",
        description = "Cpplint is a command-line tool to check C/C++ files for style issues following Google's C++ style guide",
    },
    method = DIAGNOSTICS,
    filetypes = { "cpp", "c" },
    generator_opts = {
        command = "cpplint",
        args = {
            "$FILENAME",
        },
        format = "line",
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_pattern(
            "[^:]+:(%d+):  (.+)  %[(.+)%/.+%] %[%d+%]",
            { "row", "message", "severity" },
            {
                severities = {
                    build = h.diagnostics.severities["warning"],
                    whitespace = h.diagnostics.severities["hint"],
                    runtime = h.diagnostics.severities["warning"],
                    legal = h.diagnostics.severities["information"],
                    readability = h.diagnostics.severities["information"],
                },
            }
        ),
        check_exit_code = function(code)
            return code >= 1
        end,
    },
    factory = h.generator_factory,
})
