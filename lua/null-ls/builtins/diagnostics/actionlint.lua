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
        format = "json_raw",
        from_stderr = true,
        to_stdin = true,
        on_output = function(params)
            local parser = h.diagnostics.from_json({
                attributes = {
                    message = "message",
                    row = "line",
                    col = "column",
                    source = "actionlint",
                    code = "kind",
                    file = "filename",
                    severity = 1,
                },
            })

            return parser({ output = params.output })
        end,
    },
    factory = h.generator_factory,
})
