local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "ktlint",
    meta = {
        url = "https://ktlint.github.io/",
        description = "An anti-bikeshedding Kotlin linter with built-in formatter.",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "kotlin" },
    generator_opts = {
        command = "ktlint",
        args = {
            "--relative",
            "--reporter=json",
        },
        to_stdin = true,
        format = "json",
        multiple_files = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            params.messages = {}
            local severity = vim.diagnostic.severity
            for _, output in pairs(params.output) do
                local filename = output.file
                for _, error in pairs(output.errors) do
                    local s = error.rule == "" and "ERROR" or "WARN"
                    table.insert(params.messages, {
                        row = error.line,
                        col = error.column,
                        message = error.message,
                        severity = severity[s],
                        filename = filename,
                        source = "ktlint",
                    })
                end
            end
            return params.messages
        end,
    },
    factory = h.generator_factory,
})
