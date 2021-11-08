local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "phpstan",
        args = { "analyze", "--error-format", "json", "--no-progress", "$FILENAME" },
        format = "json_raw",
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local parser = h.diagnostics.from_json({})
            params.messages = params.output
                    and params.output.files
                    and params.output.files[params.temp_path]
                    and params.output.files[params.temp_path].messages
                or {}

            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})
