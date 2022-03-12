local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local INFO = vim.diagnostic.severity.INFO
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "djlint",
    meta = {
        url = "https://github.com/Riverside-Healthcare/djLint",
        description = "✨ 📜 🪄 ✨ HTML Template Linter and Formatter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "django", "jinja.html", "htmldjango" },
    generator_opts = {
        command = "djlint",
        args = { "$FILENAME" },
        from_stderr = false,
        ignore_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[%w+ (%d+):(%d+) ([^.]+%.)]],
                groups = { "row", "col", "message" },
                overrides = {
                    diagnostic = { severity = INFO },
                    offsets = { col = 1 },
                },
            },
        }),
    },
    factory = h.generator_factory,
})
