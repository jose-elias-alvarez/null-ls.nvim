local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_erb_lint_output = function(params)
    if params.output and params.output.files then
        local file = params.output.files[1]
        if file and file.offenses then
            local parser = h.diagnostics.from_json({})
            local offenses = {}

            for _, offense in ipairs(file.offenses) do
                table.insert(offenses, {
                    message = offense.message,
                    ruleId = offense.linter,
                    line = offense.location.start_line,
                    column = offense.location.start_column,
                    endLine = offense.location.last_line,
                    endColumn = offense.location.last_column + 1,
                })
            end

            return parser({ output = offenses })
        end
    end

    return {}
end

return h.make_builtin({
    name = "erb-lint",
    meta = {
        url = "https://github.com/Shopify/erb-lint",
        description = "Lint your ERB or HTML files",
    },
    method = DIAGNOSTICS,
    filetypes = { "eruby" },
    generator_opts = {
        command = "erblint",
        args = { "--format", "json", "--stdin", "$FILENAME" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = handle_erb_lint_output,
    },
    factory = h.generator_factory,
})
