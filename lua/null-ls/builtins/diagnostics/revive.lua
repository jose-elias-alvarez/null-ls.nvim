local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

local severities = {
    error = vim.lsp.protocol.DiagnosticSeverity.Error,
    warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
}

return h.make_builtin({
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "go" },
    generator_opts = {
        command = "revive",
        to_stdin = false,
        from_stderr = false,
        ignore_stderr = false,
        args = {
            "-formatter",
            "json",
            "./...",
        },
        format = "json",
        multiple_files = true,
        check_exit_code = function(code)
            return code == 0
        end,
        on_output = function(params)
            local diags = {}
            for _, d in ipairs(params.output) do
                local filename = require("lspconfig.util").path.join(params.root, d.Position.Start.Filename)
                table.insert(diags, {
                    row = d.Position.Start.Line,
                    col = d.Position.Start.Column,
                    end_row = d.Position.End.Line,
                    end_col = d.Position.End.Column,
                    source = "revive",
                    message = d.Failure,
                    severity = severities[d.Severity],
                    filename = filename,
                })
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
