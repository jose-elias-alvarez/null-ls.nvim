local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

local severities = {
    error = vim.lsp.protocol.DiagnosticSeverity.Error,
    warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
    ignored = vim.lsp.protocol.DiagnosticSeverity.Information,
}

return h.make_builtin({
    name = "staticcheck",
    meta = {
        url = "https://staticcheck.io/",
        description = "Advanced Go linter.",
        notes = {
            "`extra_args` does not work with this linter, since it does not support additional non-file arguments after the first file or `./...` is specified. Overwrite `args` instead.",
        },
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "go" },
    generator_opts = {
        command = "staticcheck",
        to_stdin = false,
        from_stderr = false,
        ignore_stderr = false,
        args = {
            "-f",
            "json",
            "./...",
        },
        format = "line",
        multiple_files = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(line)
            local decoded = vim.json.decode(line)
            return {
                row = decoded.location.line,
                col = decoded.location.column,
                end_row = decoded["end"]["line"],
                end_col = decoded["end"]["culumn"],
                source = "staticcheck",
                code = decoded.code,
                message = decoded.message,
                severity = severities[decoded.severity],
                filename = decoded.location.file,
            }
        end,
    },
    factory = h.generator_factory,
})
