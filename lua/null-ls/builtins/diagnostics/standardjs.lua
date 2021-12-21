local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact" },
    generator_opts = {
        command = "standard",
        args = { "--stdin" },
        to_stdin = true,
        ignore_stderr = true,
        format = "line",
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = h.diagnostics.from_pattern(":(%d+):(%d+): (.*)", { "row", "col", "message" }, {
            diagnostic = {
                severity = h.diagnostics.severities.error,
            },
        }),
    },
    factory = h.generator_factory,
})
