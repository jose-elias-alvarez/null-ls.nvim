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

-- User defined diagnostic attribute adapters
local diagnostic_adapters = {
    end_col = {
        from_quote = {
            end_col = function(entries, line)
                local end_col = entries["end_col"]
                local quote = entries["_quote"]
                if end_col or not quote or not line then
                    return end_col
                end

                _, end_col = line:find(quote, 1, true)
                return end_col and end_col > tonumber(entries["col"]) and end_col or nil
            end,
        },
        from_length = {
            end_col = function(entries)
                local col = tonumber(entries["col"])
                local length = tonumber(entries["_length"])
                return col + length
            end,
        },
    },
}

local make_attr_adapters = function(severities, user_adapters)
    local adapters = {
        severity = function(entries, _)
            return severities[entries["severity"]]
        end,
    }
    for _, adapter in ipairs(user_adapters) do
        adapters = vim.tbl_extend("force", adapters, adapter)
    end

    return adapters
end

local make_diagnostic = function(entries, defaults, attr_adapters, params, offsets)
    if not (entries["row"] and entries["message"]) then
        return nil
    end

    local content_line = params.content and params.content[tonumber(entries["row"])] or nil
    for attr, adapter in pairs(attr_adapters) do
        entries[attr] = adapter(entries, content_line) or entries[attr]
    end
    entries["severity"] = entries["severity"] or default_severities["error"]

    -- Unset private attributes
    for k, _ in pairs(entries) do
        if k:find("^_") then
            entries[k] = nil
        end
    end

    local diagnostic = vim.tbl_extend("keep", defaults, entries)
    for k, offset in pairs(offsets) do
        diagnostic[k] = diagnostic[k] and diagnostic[k] + offset
    end
    return diagnostic
end

--- Parse a linter's output using a regex pattern
-- @param pattern The regex pattern
-- @param groups The groups defined by the pattern: {"line", "message", "col", ["end_col"], ["code"], ["severity"]}
-- @param overrides A table providing overrides for {adapters, diagnostic, severities, offsets}
-- @param overrides.diagnostic An optional table of diagnostic default values
-- @param overrides.severities An optional table of severity overrides (see default_severities)
-- @param overrides.adapters An optional table of adapters from Regex matches to diagnostic attributes
-- @param overrides.offsets An optional table of offsets to apply to diagnostic ranges
local from_pattern = function(pattern, groups, overrides)
    overrides = overrides or {}
    local severities = vim.tbl_extend("force", default_severities, overrides.severities or {})
    local defaults = overrides.diagnostic or {}
    local offsets = overrides.offsets or {}
    local attr_adapters = make_attr_adapters(severities, overrides.adapters or {})

    return function(line, params)
        local results = { line:match(pattern) }
        local entries = {}

        for i, match in ipairs(results) do
            entries[groups[i]] = match
        end

        return make_diagnostic(entries, defaults, attr_adapters, params, offsets)
    end
end

--- Parse a linter's output using multiple regex patterns until one matches
-- @param matchers A table containing the parameters to use for each pattern
-- @param matchers.pattern The regex pattern
-- @param matchers.groups The groups defined by the pattern
-- @param matchers.overrides A table providing overrides for {adapters, diagnostic, severities, offsets}
-- @param matchers.overrides.diagnostic An optional table of diagnostic default values
-- @param matchers.overrides.severities An optional table of severity overrides (see default_severities)
-- @param matchers.overrides.adapters An optional table of adapters from Regex matches to diagnostic attributes
-- @param matchers.overrides.offsets An optional table of offsets to apply to diagnostic ranges
local from_patterns = function(matchers)
    return function(line, params)
        for _, matcher in ipairs(matchers) do
            local diagnostic = from_pattern(matcher.pattern, matcher.groups, matcher.overrides)(line, params)
            if diagnostic then
                return diagnostic
            end
        end
        return nil
    end
end

--- Parse a linter's output in JSON format
-- @param overrides A table providing overrides for {adapters, diagnostic, severities, offsets}
-- @param overrides.attributes An optional table of JSON to diagnostic attributes (see default_json_attributes)
-- @param overrides.diagnostic An optional table of diagnostic default values
-- @param overrides.severities An optional table of severity overrides (see default_severities)
-- @param overrides.adapters An optional table of adapters from JSON entries to diagnostic attributes
-- @param overrides.offsets An optional table of offsets to apply to diagnostic ranges
local from_json = function(overrides)
    overrides = overrides or {}
    local attributes = vim.tbl_extend("force", default_json_attributes, overrides.attributes or {})
    local severities = vim.tbl_extend("force", default_severities, overrides.severities or {})
    local defaults = overrides.diagnostic or {}
    local offsets = overrides.offsets or {}
    local attr_adapters = make_attr_adapters(severities, overrides.adapters or {})

    return function(params)
        local diagnostics = {}
        for _, json_diagnostic in ipairs(params.output) do
            local entries = {}
            for attr, json_key in pairs(attributes) do
                entries[attr] = json_diagnostic[json_key]
            end

            local diagnostic = make_diagnostic(entries, defaults, attr_adapters, params, offsets)
            if diagnostic then
                table.insert(diagnostics, diagnostic)
            end
        end

        return diagnostics
    end
end

M.chktex = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "tex" },
    generator_opts = {
        command = "chktex",
        to_stdin = true,
        args = {
            -- Disable printing version information to stderr
            "-q",
            -- Disable executing \input statements
            "-I0",
            -- Format output
            "-f%l:%c:%d:%k:%m\n",
        },
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = from_pattern(
            [[(%d+):(%d+):(%d+):(%w+):(.+)]], --
            { "row", "col", "_length", "severity", "message" },
            {
                adapters = {
                    diagnostic_adapters.end_col.from_length,
                },
                severities = {
                    Error = default_severities["error"],
                    Warning = default_severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})

M.luacheck = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "lua" },
    generator_opts = {
        command = "luacheck",
        to_stdin = true,
        to_stderr = true,
        args = {
            "--formatter",
            "plain",
            "--codes",
            "--ranges",
            "--filename",
            "$FILENAME",
            "-",
        },
        format = "line",
        on_output = from_pattern(
            [[:(%d+):(%d+)-(%d+): %((%a)(%d+)%) (.*)]],
            { "row", "col", "end_col", "severity", "code", "message" },
            {
                adapters = {
                    diagnostic_adapters.end_col.from_quote,
                },
                severities = {
                    E = default_severities["error"],
                    W = default_severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})

M.write_good = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "write-good",
        args = { "--text=$TEXT", "--parse" },
        format = "line",
        check_exit_code = { 0, 255 },
        on_output = from_pattern(
            [[(%d+):(%d+):("([%w%s]+)".*)]], --
            { "row", "col", "message", "_quote" },
            {
                adapters = { diagnostic_adapters.end_col.from_quote },
                offsets = { col = 1, end_col = 1 },
            }
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
        on_output = from_patterns({
            {
                pattern = [[:(%d+):(%d+) [%w-/]+ (.*)]],
                groups = { "row", "col", "message" },
            },
            {
                pattern = [[:(%d+) [%w-/]+ (.*)]],
                groups = { "row", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})

M.vale = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "vale",
        format = "json",
        to_stdin = true,
        args = function(params)
            return { "--no-exit", "--output", "JSON", "--ext", "." .. vim.fn.fnamemodify(params.bufname, ":e") }
        end,
        on_output = function(params)
            local diagnostics = {}
            local severities = { error = 1, warning = 2, suggestion = 4 }
            for _, diagnostic in ipairs(params.output["stdin." .. vim.fn.fnamemodify(params.bufname, ":e")]) do
                table.insert(diagnostics, {
                    row = diagnostic.Line,
                    col = diagnostic.Span[1],
                    end_col = diagnostic.Span[2] + 1,
                    code = diagnostic.Check,
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
        on_output = from_patterns({
            {
                pattern = [[:(%d+):(%d+): (.* ['"]?([%w%.%-]+)['"]?)$]], --
                groups = { "row", "col", "message", "_quote" },
                overrides = {
                    adapters = { diagnostic_adapters.end_col.from_quote },
                    diagnostic = { source = "tl check" },
                },
            },
            {
                pattern = [[:(%d+):(%d+): (.*)]], --
                groups = { "row", "col", "message" },
                overrides = { diagnostic = { source = "tl check" } },
            },
        }),
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
        on_output = from_json({
            severities = {
                info = default_severities["information"],
                style = default_severities["hint"],
            },
        }),
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
            [[(%d+):(%d+): (%w+)%[([%w_]+)%]: ([`]*([%w_]+)[`]*.*)]],
            { "row", "col", "severity", "code", "message", "_quote" },
            { adapters = { diagnostic_adapters.end_col.from_quote } }
        ),
    },
    factory = h.generator_factory,
})

M.eslint = h.make_builtin({
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
        on_output = function(params)
            params.messages = params.output and params.output[1] and params.output[1].messages or {}
            if params.err then
                table.insert(params.messages, { message = params.err })
            end

            local parser = from_json({
                attributes = {
                    severity = "severity",
                },
                severities = {
                    default_severities["warning"],
                    default_severities["error"],
                },
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
        on_output = from_json({
            attributes = { code = "code" },
            severities = {
                info = default_severities["information"],
                style = default_severities["hint"],
            },
        }),
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
            [[:(%d+):(%d+): (([EFW])%w+) (.*)]], --
            { "row", "col", "code", "severity", "message" },
            {
                severities = {
                    E = default_severities["error"],
                    W = default_severities["warning"],
                    F = default_severities["information"],
                },
            }
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
            { diagnostic = { severity = default_severities["information"] } }
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
        on_output = from_json({
            attributes = {
                row = "line_number",
                col = "column_number",
                code = "policy_name",
                severity = "severity",
                message = "description",
            },
            severities = {
                style_problem = default_severities["information"],
            },
        }),
    },
    factory = h.generator_factory,
})

return M
