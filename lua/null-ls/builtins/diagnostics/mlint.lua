local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "mlint",
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "matlab" },
    generator_opts = {
        command = "mlint",
        args = { "$FILENAME", "-id" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[L (%d+) .C (%d).*:.*: (.*)]],
                groups = { "row", "col", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
