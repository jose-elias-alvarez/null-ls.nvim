local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "zsh",
    meta = {
        url = "https://www.zsh.org/",
        description = "Uses zsh's own -n option to evaluate, but not execute, zsh scripts. Effectively, this acts somewhat like a linter, although it only really checks for serious errors - and will likely only show the first error.",
    },
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
