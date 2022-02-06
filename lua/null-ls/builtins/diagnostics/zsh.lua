local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "zsh",
    method = DIAGNOSTICS,
    filetypes = { "zsh" },
    generator_opts = {
        command = "zsh",
        args = {
            "-n",
            "$FILENAME",
        },
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code >= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(.+):(%d+): (.+)]],
                groups = { "filename", "row", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
