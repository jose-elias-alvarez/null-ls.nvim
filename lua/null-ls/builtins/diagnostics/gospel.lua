local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "gospel",
    meta = {
        url = "https://github.com/kortschak/gospel",
        description = "misspelled word linter for Go comments, string literals and embedded files",
    },
    method = DIAGNOSTICS,
    filetypes = { "go" },
    generator_opts = {
        command = "gospel",
        args = { "$DIRNAME" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern([[(%g+):(%d+):(%d+): (.+)]], { "file", "row", "col", "message" }),
    },
    factory = h.generator_factory,
})
