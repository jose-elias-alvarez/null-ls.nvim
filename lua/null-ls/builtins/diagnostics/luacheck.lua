local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "lua" },
    generator_opts = {
        command = "luacheck",
        to_stdin = false,
        from_stderr = true,
        args = {
            "--formatter",
            "plain",
            "--codes",
            "--ranges",
            "$ROOT",
        },
        format = "line",
        multiple_files = true,
        on_output = h.diagnostics.from_pattern(
            [[(.+):(%d+):(%d+)-(%d+): %((%a)(%d+)%) (.*)]],
            { "filename", "row", "col", "end_col", "severity", "code", "message" },
            {
                adapters = {
                    h.diagnostics.adapters.end_col.from_quote,
                },
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                },
                offsets = { end_col = 1 },
            }
        ),
    },
    factory = h.generator_factory,
})
