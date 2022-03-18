local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_semgrep_output = function(params)
    local file = params.output
    if file and file.results then
        local parser = h.diagnostics.from_json({
            severities = {
                INFO = h.diagnostics.severities.information,
                WARNING = h.diagnostics.severities.warning,
                ERROR = h.diagnostics.severities.error,
            },
        })

        local offenses = {}

        for _, offense in ipairs(file.results) do
            table.insert(offenses, {
                message = offense.extra.message,
                ruleId = offense.check_id,
                level = offense.extra.severity,
                line = offense.start.line,
                column = offense.start.col,
                endLine = offense["end"].line,
                endColumn = offense["end"].col,
            })
        end

        return parser({ output = offenses })
    end

    return {}
end

return h.make_builtin({
    name = "semgrep",
    meta = {
        url = "https://semgrep.dev/",
        description = "Semgrep is a fast, open-source, static analysis tool for finding bugs and enforcing code standards at editor, commit, and CI time.",
    },
    method = DIAGNOSTICS,
    filetypes = { "typescript", "typescriptreact", "ruby", "python", "java", "go" },
    generator_opts = {
        command = "semgrep",
        args = { "-q", "--json", "$FILENAME" },
        format = "json",
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = handle_semgrep_output,
    },
    factory = h.generator_factory,
})
