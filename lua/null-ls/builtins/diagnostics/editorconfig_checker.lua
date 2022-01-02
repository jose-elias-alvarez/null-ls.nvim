local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "editorconfig_checker",
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "ec",
        args = {
            "-no-color",
            "$FILENAME",
        },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern([[(%d+): (.+)]], { "row", "message" }),
    },
    factory = h.generator_factory,
})
