local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "pylint",
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
