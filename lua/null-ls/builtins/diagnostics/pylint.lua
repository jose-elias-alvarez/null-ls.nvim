local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "pylint",
    meta = {
        url = "https://github.com/PyCQA/pylint",
        description = "Pylint is a Python static code analysis tool which looks for programming errors, helps enforcing a coding standard, sniffs for code smells and offers simple refactoring suggestions.",
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "pylint",
        to_stdin = true,
        args = { "--from-stdin", "$FILENAME", "-f", "json" },
        format = "json",
        check_exit_code = function(code)
            return code ~= 32
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line",
                col = "column",
                code = "message-id",
                severity = "type",
                message = "message",
                symbol = "symbol",
                source = "pylint",
            },
            severities = {
                convention = h.diagnostics.severities["information"],
                refactor = h.diagnostics.severities["information"],
            },
            offsets = {
                col = 1,
            },
        }),
    },
    factory = h.generator_factory,
})
