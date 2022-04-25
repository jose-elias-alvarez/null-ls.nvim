local u = require("null-ls.utils")

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
                if end_col and end_col > tonumber(entries["col"]) then
                    return end_col + 1
                end
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
            return severities[entries["severity"]] or severities["_fallback"]
        end,
    }
    for _, adapter in ipairs(user_adapters) do
        adapters = vim.tbl_extend("force", adapters, adapter)
    end

    return adapters
end

local make_diagnostic = function(entries, defaults, attr_adapters, params, offsets)
    if not entries["message"] then
        return nil
    end

    local content_line = params.content and params.content[tonumber(entries["row"])] or nil
    for attr, adapter in pairs(attr_adapters) do
        entries[attr] = adapter(entries, content_line)
    end

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

--- Parse a linter's output using a errorformat
-- @param efm A comma separated list of errorformats
-- @param source Source name.
local from_errorformat = function(efm, source)
    return function(params, done)
        local output = params.output
        if not output then
            return done()
        end

        local diagnostics = {}
        local lines = u.split_at_newline(params.bufnr, output)

        local qflist = vim.fn.getqflist({ efm = efm, lines = lines })
        local severities = { e = 1, w = 2, i = 3, n = 4 }

        for _, item in pairs(qflist.items) do
            if item.valid == 1 then
                local col = item.col > 0 and item.col - 1 or 0
                table.insert(diagnostics, {
                    row = item.lnum,
                    col = col,
                    source = source,
                    message = item.text,
                    severity = severities[item.type],
                })
            end
        end

        return done(diagnostics)
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
                if json_diagnostic[json_key] ~= vim.NIL then
                    entries[attr] = json_diagnostic[json_key]
                end
            end

            local diagnostic = make_diagnostic(entries, defaults, attr_adapters, params, offsets)
            if diagnostic then
                table.insert(diagnostics, diagnostic)
            end
        end

        return diagnostics
    end
end

return {
    adapters = diagnostic_adapters,
    severities = default_severities,
    from_pattern = from_pattern,
    from_patterns = from_patterns,
    from_errorformat = from_errorformat,
    from_json = from_json,
}
