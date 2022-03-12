local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local severities = {
    error = vim.lsp.protocol.DiagnosticSeverity.Error,
    warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
}

return h.make_builtin({
    name = "puppet-lint",
    meta = {
        url = "http://puppet-lint.com/",
        description = "Check that your Puppet manifest conforms to the style guide.",
    },
    method = methods.internal.DIAGNOSTICS,
    filetypes = { "puppet", "epuppet" },
    generator_opts = {
        command = "puppet-lint",
        args = { "--json", "$FILENAME" },
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local diags = {}
            for _, d in ipairs(params.output) do
                for _, f in ipairs(d) do
                    table.insert(diags, {
                        row = f.line,
                        col = f.column,
                        source = f.check,
                        message = f.message,
                        severity = severities[f.kind],
                        filename = f.fullpath,
                    })
                end
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
