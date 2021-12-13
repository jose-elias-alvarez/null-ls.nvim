local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "scss", "less", "css", "sass" },
    generator_opts = {
        command = "stylelint",
        args = { "--formatter", "json", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        on_output = function(params)
            params.messages = params.output and params.output[1] and params.output[1].warnings or {}

            if params.err then
                table.insert(params.messages, { text = params.err })
            end

            local parser = h.diagnostics.from_json({
                attributes = {
                    severity = "severity",
                    message = "text",
                },
                severities = {
                    h.diagnostics.severities["warning"],
                    h.diagnostics.severities["error"],
                },
            })

            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})
