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
                -- NOTE: We don"t get JSON here
                for _, v in pairs(vim.fn.json_decode(params.err)) do
                    for _, e in pairs(v.warnings) do
                        table.insert(params.messages, e)
                    end
                end
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
