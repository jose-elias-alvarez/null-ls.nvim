local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "alex",
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "alex",
        args = { "--stdin", "--quiet" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[ *(%d+):(%d+)-(%d+):(%d+) *(%w+) *(.+) +[%w]+ +([-%l]+)]],
                groups = { "row", "col", "end_row", "end_col", "severity", "message", "code" },
            },
        }),
    },
})
