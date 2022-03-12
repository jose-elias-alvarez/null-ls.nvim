local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "misspell",
    meta = {
        url = "https://github.com/client9/misspell",
        description = "Checks commonly misspelled English words in source files.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "misspell",
        to_stdin = true,
        format = "line",
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): (.*)]],
            { "row", "col", "message" },
            { diagnostic = { severity = h.diagnostics.severities["information"] }, offsets = { col = 1 } }
        ),
    },
    factory = h.generator_factory,
})
