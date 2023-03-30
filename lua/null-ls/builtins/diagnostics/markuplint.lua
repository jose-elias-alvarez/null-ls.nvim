local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "markuplint",
    meta = {
        url = "https://github.com/markuplint/markuplint",
        description = "A linter for all markup developers.",
    },
    filetypes = { "html" },
    method = methods.internal.DIAGNOSTICS,
    generator_opts = {
        command = "markuplint",
        to_temp_file = true,
        ignore_stderr = true,
        args = { "--format", "JSON", "$FILENAME" },
        format = "json",
        on_output = h.diagnostics.from_json({
            attributes = {
                message = "message",
                source = "markuplint",
                code = "ruleId",
                severity = "severity",
                row = "line",
                end_row = "line",
                col = "col",
                end_col = "col",
            },
        }),
    },
    factory = h.generator_factory,
})
