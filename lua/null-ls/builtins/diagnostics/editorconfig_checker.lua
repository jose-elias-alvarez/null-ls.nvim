local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "editorconfig_checker",
    meta = {
        url = "https://github.com/editorconfig-checker/editorconfig-checker",
        description = "A tool to verify that your files are in harmony with your `.editorconfig`.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "editorconfig-checker",
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
