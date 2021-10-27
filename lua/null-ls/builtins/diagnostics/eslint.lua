local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_eslint_output = function(params)
    params.messages = params.output and params.output[1] and params.output[1].messages or {}
    if params.err then
        table.insert(params.messages, { message = params.err })
    end

    local parser = h.diagnostics.from_json({
        attributes = {
            severity = "severity",
        },
        severities = {
            h.diagnostics.severities["warning"],
            h.diagnostics.severities["error"],
        },
    })

    return parser({ output = params.messages })
end

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    generator_opts = {
        command = "eslint",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = handle_eslint_output,
    },
    factory = h.generator_factory,
})
