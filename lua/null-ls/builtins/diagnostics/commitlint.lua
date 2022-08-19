local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local violation_to_diagnostic = function(violation)
    local diagnostic = {
        ruleId = violation.name,
        message = violation.message,
        level = violation.level,
    }

    if violation.name == "body-leading-blank" then
        diagnostic.line = 2
    elseif vim.startswith(violation.name, "body") then
        diagnostic.line = 3
    end

    return diagnostic
end

local handle_commitlint_output = function(params)
    if params.output and params.output.results then
        local output = params.output.results[1]

        local parser = h.diagnostics.from_json({
            severities = {
                [1] = h.diagnostics.severities.warning,
                [2] = h.diagnostics.severities.error,
            },
        })

        local violations = {}
        for _, violation in ipairs(output.errors) do
            table.insert(violations, violation_to_diagnostic(violation))
        end

        for _, violation in ipairs(output.warnings) do
            table.insert(violations, violation_to_diagnostic(violation))
        end

        return parser({ output = violations })
    end
end

return h.make_builtin({
    name = "commitlint",
    meta = {
        url = "https://commitlint.js.org",
        description = "commitlint checks if your commit messages meet the conventional commit format.",
        notes = {
            "Needs npm packages commitlint and a json formatter: `@commitlint/{config-conventional,cli}` and `commitlint-format-json`.",
            "It works with the packages installed globally but watch out for [some common issues](https://github.com/conventional-changelog/commitlint/issues/613).",
        },
    },
    method = DIAGNOSTICS,
    filetypes = { "gitcommit" },
    generator_opts = {
        command = "commitlint",
        args = { "--format", "commitlint-format-json" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = handle_commitlint_output,
    },
    factory = h.generator_factory,
})
