local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "textidote",
    meta = {
        url = "https://github.com/sylvainhalle/textidote",
        description = "Spelling, grammar and style checking on LaTeX documents",
    },
    method = DIAGNOSTICS,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "textidote",
        args = {
            "--quiet",
            "--no-color",
            "--check",
            "en",
            "--output",
            "singleline",
            "$FILENAME",
        },
        format = "line",
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(.*)(L(%d+)C(%d+)-L(%d+)C(%d+)): (.*)]],
                groups = { "filename", "row", "col", "end_row", "end_col", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
