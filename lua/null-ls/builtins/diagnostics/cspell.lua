local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cspell",
    meta = {
        url = "https://github.com/streetsidesoftware/cspell",
        description = "cspell is a spell checker for code.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "cspell",
        args = function(params)
            return {
                "--language-id",
                params.ft,
                "stdin",
            }
        end,
        to_stdin = true,
        ignore_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[.*:(%d+):(%d+)%s*-%s*(.*%((.*)%))]],
            { "row", "col", "message", "_quote" },
            {
                adapters = { h.diagnostics.adapters.end_col.from_quote },
            }
        ),
    },
    factory = h.generator_factory,
})
