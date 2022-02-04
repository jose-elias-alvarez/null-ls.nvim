local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cspell",
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
                offsets = { end_col = 1 },
                severities = {
                    ["_fallback"] = h.diagnostics.severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
