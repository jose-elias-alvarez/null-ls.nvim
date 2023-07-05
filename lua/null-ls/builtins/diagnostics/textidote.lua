local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_OPEN = methods.internal.DIAGNOSTICS_ON_OPEN
local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "textidote",
    meta = {
        url = "https://github.com/sylvainhalle/textidote",
        description = "Spelling, grammar and style checking on LaTeX documents.",
    },
    method = { DIAGNOSTICS_ON_OPEN, DIAGNOSTICS_ON_SAVE },
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "textidote",
        args = {
            "--read-all",
            "--output",
            "singleline",
            "--no-color",
            "--check",
            "en",
            "--quiet",
            "$FILENAME",
        },
        format = "line",
        timeout = 5000,
        ignore_stderr = true,
        to_stdin = true,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(.*)%(L(%d+)C(%d+)-L(%d+)C(%d+)%): (.*)]],
                groups = { "filename", "row", "col", "end_row", "end_col", "message" },
                overrides = {
                    diagnostic = {
                        severity = h.diagnostics.severities.warning,
                    },
                },
            },
        }),
        multiple_files = true,
    },
    factory = h.generator_factory,
})
