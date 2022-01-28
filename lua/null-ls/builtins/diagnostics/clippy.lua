local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_output = function(params)
    local messages = {}
    for line in string.gmatch(params.output, "[^\n]+") do
        local ok, decoded = pcall(vim.json.decode, line)
        if ok and decoded.message and decoded.message.spans and decoded.message.spans[1] and decoded.message.code then
            local src = decoded.message
            local span = src.spans[1]
            local message = {
                line = span.line_start,
                column = span.column_start,
                endLine = span.line_end,
                endColumn = span.column_end,
                ruleId = src.code.code,
                level = src.level,
                message = src.rendered,
            }
            table.insert(messages, message)
        end
    end

    local parser = h.diagnostics.from_json({
        severities = {
            error = h.diagnostics.severities["error"],
            warning = h.diagnostics.severities["warning"],
            note = h.diagnostics.severities["information"],
            hint = h.diagnostics.severities["hint"],
        },
    })

    return parser({ output = messages })
end

return h.make_builtin({
    name = "clippy",
    method = DIAGNOSTICS,
    filetypes = { "rust" },
    generator_opts = {
        command = "cargo",
        format = "json_raw",
        args = { "clippy", "--frozen", "--message-format=json", "-q", "--" },
        check_exit_code = { 0 },
        on_output = handle_output,
    },
    factory = h.generator_factory,
})
