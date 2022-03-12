local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "pylama",
    meta = {
        url = "https://github.com/klen/pylama",
        description = "Code audit tool for Python.",
    },
    method = methods.internal.DIAGNOSTICS,
    filetypes = { "python" },
    factory = h.generator_factory,
    generator_opts = {
        command = "pylama",
        to_stdin = true,
        from_stderr = false,
        ignore_stderr = true,
        args = { "--from-stdin", "$FILENAME", "-f", "json" },
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                message = "message",
                row = "lnum",
                col = "col",
                severity = "etype",
                code = "number",
                source = "source",
            },
            severities = {
                E = h.diagnostics.severities["error"],
                W = h.diagnostics.severities["warning"],
                S = h.diagnostics.severities["warning"],
                I = h.diagnostics.severities["warning"],
                C = h.diagnostics.severities["warning"],
                T = h.diagnostics.severities["warning"],
                F = h.diagnostics.severities["information"],
                D = h.diagnostics.severities["information"],
                R = h.diagnostics.severities["information"],
            },
        }),
    },
})
