local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

-- NOTE: Unused
--[==[ local violation_to_diagnostic = function(violation)
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
--]==]

-- NOTE: Unused
--[==[ local handle_commitlint_output = function(params)
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
--]==]

---@param line string
local function get_severity(line)
    local severities = {
        ["✖"] = vim.diagnostic.severity.ERROR,
        ["⚠"] = vim.diagnostic.severity.WARN,
        -- NOTE: ↓ INFO is currently disable since it doesn't seem to produce anything but the same link
        -- ['^ⓘ'] = vim.diagnostic.severity.INFO
    }
    for pattern, severity in pairs(severities) do
        -- NOTE: Can be  used to futher improve parsing.
        local pos = { vim.regex("^" .. pattern):match_str(line) }

        return pos ~= nil and severity
    end
end

---@param line string: line from command output
---@param _ {}: `params`
local function on_output(line, _)
    local valid_line = line:match("]$") and line

    if not valid_line then
        return nil
    else
        local severity = get_severity(valid_line)
        return severity
                and {
                    row = 1,
                    col = 1,
                    source = "commitlint",
                    message = valid_line:match("%s%s%s(.*)%[.*"),
                    code = valid_line:match("%[.*%]"),
                    severity = severity,
                    filename = "",
                }
            or nil
    end
end

return h.make_builtin({
    name = "commitlint",
    meta = {
        url = "https://commitlint.js.org",
        description = "commitlint checks if your commit messages meet the conventional commit format.",
        notes = {
            -- "Needs npm packages commitlint and a json formatter: `@commitlint/{config-conventional,cli}` and `commitlint-format-json`.",
            -- "It works with the packages installed globally but watch out for [some common issues](https://github.com/conventional-changelog/commitlint/issues/613).",
            -- [=[Needs a `commitlintrc.json` configuration file, [schema](https://json.schemastore.org/commitlintrc.json).]=],
        },
    },
    method = DIAGNOSTICS,
    filetypes = { "gitcommit" },
    generator_opts = {
        command = "commitlint",
        -- args = { "--format", "commitlint-format-json" },
        -- NOTE: Maybe add a function for resolving the configuration path?
        args = { "--edit", "$FILENAME" },
        -- to_stdin = true,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = on_output,
    },
    factory = h.generator_factory,
})
