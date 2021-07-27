local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local M = {}

local default_severities = {
    ["error"] = 1,
    ["warning"] = 2,
    ["information"] = 3,
    ["hint"] = 4,
}

local default_json_attributes = {
    row = "line",
    col = "column",
    end_row = "endLine",
    end_col = "endColumn",
    code = "ruleId",
    severity = "level",
    message = "message",
}

local make_attribute_handlers = function(severities, defaults)
    return {
        row = function(entries)
            return tonumber(entries["row"])
        end,
        col = function(entries)
            return tonumber(entries["col"])
        end,
        end_row = function(entries)
            return tonumber(entries["end_row"]) or tonumber(entries["row"])
        end,
        end_col = function(entries)
            return tonumber(entries["end_col"]) or tonumber(entries["col"])
        end,
        code = function(entries)
            return entries["code"]
        end,
        severity = function(entries)
            local severity = entries["severity"]
            return severities[severity] or defaults["severity"] or default_severities["error"]
        end,
        message = function(entries)
            return entries["message"]
        end,
    }
end

--- Parse a linter's output using a regex pattern
-- @param pattern The regex pattern
-- @param groups The groups defined by the pattern: {"line", "message", "col", ["end_col"], ["code"], ["severity"]}
-- @param severities An optional table of severity overrides (see default_severities)
-- @param defaults An optional table of diagnostic default values
local from_pattern = function(pattern, groups, severities, defaults)
    severities = vim.tbl_extend("force", default_severities, severities or {})
    defaults = defaults or {}
    local attribute_handlers = make_attribute_handlers(severities, defaults)
    return function(line, params)
        local results = { line:match(pattern) }
        local entries = {}

        for i, match in ipairs(results) do
            entries[groups[i]] = match
        end
        if not (entries["row"] and entries["message"]) then
            return nil
        end

        local diagnostic = {}
        for key, handler in pairs(attribute_handlers) do
            diagnostic[key] = defaults[key] or handler(entries)
        end

        return diagnostic
    end
end

--- Parse a linter's output using multiple regex patterns until one matches
-- @param patterns The regex pattern list
-- @param groups The groups list defined by the patterns
-- @param severities An optional table of severity overrides (see default_severities)
-- @param defaults An optional table of diagnostic default values
local from_patterns = function(patterns, groups, severities, defaults)
    return function()
        for i, pattern in ipairs(patterns) do
            local diagnostic = from_pattern(pattern, groups[i], severities, defaults)
            if diagnostic then
                return diagnostic
            end
        end
        return nil
    end
end

--- Parse a linter's output in JSON format
-- @param attributes An optional table of JSON to diagnostic attributes overrides (see default_json_attributes)
-- @param severities An optional table of severity overrides (see default_severities)
-- @param defaults An optional table of diagnostic default values
local from_json = function(attributes, severities, defaults)
    attributes = vim.tbl_extend("force", default_json_attributes, attributes or {})
    severities = vim.tbl_extend("force", default_severities, severities or {})
    defaults = defaults or {}
    local attribute_handlers = make_attribute_handlers(severities, defaults)
    return function(params)
        local diagnostics = {}
        for _, json_diagnostic in ipairs(params.output) do
            local entries = {}
            for diagnostic_key, json_key in pairs(attributes) do
                entries[diagnostic_key] = json_diagnostic[json_key]
            end

            if entries["row"] and entries["message"] then
                local diagnostic = {}
                for key, handler in pairs(attribute_handlers) do
                    diagnostic[key] = defaults[key] or handler(entries)
                end
                table.insert(diagnostics, diagnostic)
            end
        end

        return diagnostics
    end
end

M.write_good = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "write-good",
        args = { "--text=$TEXT", "--parse" },
        format = "line",
        check_exit_code = function(code)
            return code == 0 or code == 255
        end,
        on_output = from_pattern(
            [[(%d+):(%d+):(.*)]], --
            { "row", "col", "message" },
            nil,
            { source = "write-good" }
        ),
    },
    factory = h.generator_factory,
})

M.markdownlint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint",
        args = { "--stdin" },
        to_stdin = true,
        to_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = from_patterns(
            { [[:(%d+):(%d+) [%w-/]+ (.*)]], [[:(%d+) [%w-/]+ (.*)]] },
            { { "row", "col", "message" }, { "row", "message" } },
            nil,
            { source = "markdownlint" }
        ),
    },
    factory = h.generator_factory,
})

M.vale = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "vale",
        format = "json",
        args = { "--no-exit", "--output=JSON", "$FILENAME" },
        on_output = function(params)
            local diagnostics = {}
            local severities = { error = 1, warning = 2, suggestion = 4 }
            for _, diagnostic in ipairs(params.output[params.bufname]) do
                table.insert(diagnostics, {
                    row = diagnostic.Line,
                    col = diagnostic.Span[1] - 1,
                    end_col = diagnostic.Span[2],
                    code = diagnostic.Check,
                    source = "vale",
                    message = diagnostic.Message,
                    severity = severities[diagnostic.Severity],
                })
            end
            return diagnostics
        end,
    },
    factory = h.generator_factory,
})

M.teal = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "teal" },
    generator_opts = {
        command = "tl",
        args = { "check", "$FILENAME" },
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        to_stderr = true,
        to_temp_file = true,
        on_output = from_pattern(
            [[:(%d+):(%d+): (.*)]], --
            { "row", "col", "message" },
            { source = "tl check" }
        ),
    },
    factory = h.generator_factory,
})

M.shellcheck = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "sh" },
    generator_opts = {
        command = "shellcheck",
        args = { "--format", "json", "-" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = from_json( --
            {},
            {
                style = 4,
            },
            {
                source = "shellcheck",
            }
        ),
    },
    factory = h.generator_factory,
})

M.selene = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "lua" },
    generator_opts = {
        command = "selene",
        args = { "--display-style", "quiet", "-" },
        to_stdin = true,
        to_stderr = false,
        ignore_errors = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = from_pattern(
            [[(%d+):(%d+): (%w+)%[([%w_]+)%]: (.*)]],
            { "row", "col", "severity", "code", "message" },
            nil,
            { source = "selene" }
        ),
    },
    factory = h.generator_factory,
})

M.eslint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    generator_opts = {
        command = "eslint",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = function(params)
            params.messages = params.output and params.output[1] and params.output[1].messages or {}
            if params.err then
                table.insert(params.messages, { message = params.err })
            end

            local parser = from_json({
                severity = "severity",
            }, {
                default_severities["warning"],
                default_severities["error"],
            }, {
                source = "eslint",
            })

            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})

M.hadolint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "dockerfile" },
    generator_opts = {
        command = "hadolint",
        format = "json",
        args = { "--no-fail", "--format=json", "$FILENAME" },
        on_output = from_json( --
            { code = "code" },
            { style = 4 },
            { source = "hadolint" }
        ),
    },
    factory = h.generator_factory,
})

M.flake8 = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "flake8",
        to_stdin = true,
        to_stderr = true,
        args = { "--stdin-display-name", "$FILENAME", "-" },
        format = "line",
        check_exit_code = function(code)
            return code == 0 or code == 255
        end,
        on_output = from_pattern(
            [[:(%d+):(%d+): (([EFW])%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            { E = 1, W = 2, F = 3 },
            { source = "flake8" }
        ),
    },
    factory = h.generator_factory,
})

M.misspell = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "*" },
    generator_opts = {
        command = "misspell",
        to_stdin = true,
        args = {},
        format = "line",
        on_output = from_pattern(
            [[:(%d+):(%d+): (.*)]],
            { "row", "col", "message" },
            nil,
            { source = "misspell", severity = default_severities["information"] }
        ),
    },
    factory = h.generator_factory,
})

M.vint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "vim" },
    generator_opts = {
        command = "vint",
        format = "json",
        args = { "-s", "-j", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
        check_exit_code = function(code)
            return code == 0 or code == 1
        end,
        on_output = from_json(
            { row = "line_number", col = "column_number", code = "policy_name", message = "description" },
            { style_problem = 3 },
            { source = "vint" }
        ),
    },
    factory = h.generator_factory,
})

return M
