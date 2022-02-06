local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "actionlint",
    method = DIAGNOSTICS,
    filetypes = { "yaml" },
    generator_opts = {
        command = "actionlint",
        args = { "-no-color", "-format", "{{json .}}", "-" },
        format = "json",
        from_stderr = true,
        to_stdin = true,
        on_output = h.diagnostics.from_json({
            attributes = {
                message = "message",
                source = "actionlint",
                code = "kind",
                severity = 1,
            },
        }),
    },
    factory = h.generator_factory,
})
