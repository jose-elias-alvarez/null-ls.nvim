local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "phpstan",
    meta = {
        url = "https://github.com/phpstan/phpstan",
        description = "PHP static analysis tool.",
        notes = {
            "Requires a valid `phpstan.neon` at root.",
        },
    },
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
            params.messages = {}

            if params.output and params.output.files and type(params.output.files) == "table" then
                for k in pairs(params.output.files) do
                    params.messages = params.output.files[k].messages or {}
                    break
                end
            end

            local parser = h.diagnostics.from_json({})
            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})
