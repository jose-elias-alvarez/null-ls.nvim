local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_rubocop_output = function(params)
    if params.output and params.output.files then
        local file = params.output.files[1]
        if file and file.offenses then
            local parser = h.diagnostics.from_json({
                severities = {
                    info = h.diagnostics.severities.information,
                    refactor = h.diagnostics.severities.hint,
                    convention = h.diagnostics.severities.warning,
                    warning = h.diagnostics.severities.warning,
                    error = h.diagnostics.severities.error,
                    fatal = h.diagnostics.severities.fatal,
                },
            })
            local offenses = {}

            for _, offense in ipairs(file.offenses) do
                table.insert(offenses, {
                    message = offense.message,
                    ruleId = offense.cop_name,
                    level = offense.severity,
                    line = offense.location.start_line,
                    column = offense.start_column,
                    endLine = offense.location.last_line,
                    endColumn = offense.last_column,
                })
            end

            return parser({ output = offenses })
        end
    end

    return {}
end

return h.make_builtin({
    name = "standardrb",
    meta = {
        url = "https://github.com/testdouble/standard",
        description = "Ruby style guide, linter, and formatter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "ruby" },
    generator_opts = {
        command = "standardrb",
        args = { "--no-fix", "-f", "json", "--stdin", "$FILENAME" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = handle_rubocop_output,
    },
    factory = h.generator_factory,
})
