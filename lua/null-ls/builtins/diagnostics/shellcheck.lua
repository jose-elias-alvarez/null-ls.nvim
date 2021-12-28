local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "sh", "bash" },
    generator_opts = {
        command = "shellcheck",
        args = { "--format", "json1", "--source-path=$DIRNAME", "--external-sources", "-" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local parser = h.diagnostics.from_json({
                attributes = { code = "code" },
                severities = {
                    info = h.diagnostics.severities["information"],
                    style = h.diagnostics.severities["hint"],
                },
            })

            return parser({ output = params.output.comments })
        end,
    },
    factory = h.generator_factory,
})
