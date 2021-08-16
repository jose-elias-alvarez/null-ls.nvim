local u = require("null-ls.utils")
local c = require("null-ls.config")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local loop = require("null-ls.loop")

local api = vim.api
local validate = vim.validate

local output_formats = {
    raw = "raw", -- receive error_output and output directly
    none = nil, -- same as raw but will not send error output
    line = "line", -- call handler once per line of output
    json = "json", -- send processed json output to handler
    json_raw = "json_raw", -- attempt to process json, but send errors to handler
}

local M = {}

local get_content = function(params)
    -- when possible, get content from params
    if params.content then
        return table.concat(params.content, "\n")
    end

    -- otherwise, get content directly
    return u.buf.content(params.bufnr, true)
end

local parse_args = function(args, params)
    local parsed = {}
    for _, arg in pairs(args) do
        if string.find(arg, "$FILENAME") then
            arg = u.string.replace(arg, "$FILENAME", params.bufname)
        end
        if string.find(arg, "$TEXT") then
            arg = u.string.replace(arg, "$TEXT", get_content(params))
        end
        if string.find(arg, "$FILEEXT") then
            arg = u.string.replace(arg, "$FILEEXT", vim.fn.fnamemodify(params.bufname, ":e"))
        end

        table.insert(parsed, arg)
    end
    return parsed
end

local json_output_wrapper = function(params, done, on_output, format)
    local ok, decoded = pcall(vim.fn.json_decode, params.output)
    if decoded == vim.NIL or decoded == "" then
        decoded = nil
    end

    if not ok then
        if format ~= output_formats.json_raw then
            error("failed to decode json: " .. decoded)
        end
        params.err = decoded
    else
        params.output = decoded
    end

    -- don't bother calling on_output if output is empty
    if not params.err and (params.output == nil or vim.tbl_count(params.output) == 0) then
        done()
        return
    end

    done(on_output(params))
end

local line_output_wrapper = function(params, done, on_output)
    local output = params.output
    if not output or output == "" then
        done()
        return
    end

    local all_results = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        if line ~= "" then
            local results = on_output(line, params)
            if type(results) == "table" then
                table.insert(all_results, results)
            end
        end
    end

    done(all_results)
end

M.generator_factory = function(opts)
    local command, args, on_output, format, to_stderr, to_stdin, suppress_errors, check_exit_code, timeout, to_temp_file, use_cache =
        opts.command,
        opts.args,
        opts.on_output,
        opts.format,
        opts.to_stderr,
        opts.to_stdin,
        opts.suppress_errors,
        opts.check_exit_code,
        opts.timeout,
        opts.to_temp_file,
        opts.use_cache

    if type(check_exit_code) == "table" then
        local codes = vim.deepcopy(check_exit_code)
        check_exit_code = function(code)
            return vim.tbl_contains(codes, code)
        end
    end

    local _validated
    local validate_opts = function()
        validate({
            command = {
                command,
                function(v)
                    return type(v) == "string" and vim.fn.executable(command) > 0
                end,
                "string (executable)",
            },
            args = {
                args,
                function(v)
                    return v == nil or vim.tbl_contains({ "function", "table" }, type(v))
                end,
                "function or table",
            },
            on_output = { on_output, "function" },
            format = {
                format,
                function(a)
                    return not a or vim.tbl_contains(vim.tbl_values(output_formats), a)
                end,
                "raw, line, json, or json_raw",
            },
            to_stderr = { to_stderr, "boolean", true },
            to_stdin = { to_stdin, "boolean", true },
            suppress_errors = { suppress_errors, "boolean", true },
            check_exit_code = { check_exit_code, "function", true },
            timeout = { timeout, "number", true },
            to_temp_file = { to_temp_file, "boolean", true },
            use_cache = { use_cache, "boolean", true },
        })

        _validated = true
    end

    return {
        fn = function(params, done)
            if not _validated then
                validate_opts()
            end

            local wrapper = function(error_output, output)
                u.debug_log("error output: " .. (error_output or "nil"))
                u.debug_log("output: " .. (output or "nil"))

                if to_stderr then
                    output = error_output
                    error_output = nil
                end

                if error_output and not (format == output_formats.raw or format == output_formats.json_raw) then
                    if not suppress_errors then
                        error("error in generator output: " .. error_output)
                    end
                    done()
                    return
                end

                params.output = output
                if use_cache then
                    s.set_cache(params.bufnr, command, output)
                end

                if format == output_formats.raw or format == output_formats.json_raw then
                    params.err = error_output
                end

                if format == output_formats.json or format == output_formats.json_raw then
                    json_output_wrapper(params, done, on_output, format)
                    return
                end

                if format == output_formats.line then
                    line_output_wrapper(params, done, on_output)
                    return
                end

                on_output(params, done)
            end

            if use_cache then
                local cached = s.get_cache(params.bufnr, command)
                if cached then
                    params._null_ls_cached = true
                    wrapper(to_stderr and cached, to_stderr and nil or cached)
                    return
                end
            end

            local spawn_args = args or {}
            local client = vim.lsp.get_client_by_id(params.client_id)
            spawn_args = type(spawn_args) == "function" and spawn_args(params) or spawn_args
            local spawn_opts = {
                cwd = client and client.config.root_dir or vim.fn.getcwd(),
                input = to_stdin and get_content(params) or nil,
                handler = wrapper,
                check_exit_code = check_exit_code,
                timeout = timeout or c.get().default_timeout,
            }

            if to_temp_file then
                local temp_path, cleanup = loop.temp_file(get_content(params))

                spawn_args = u.table.replace(spawn_args, "$FILENAME", temp_path)
                spawn_opts.on_stdout_end = cleanup
            end

            spawn_args = parse_args(spawn_args, params)

            u.debug_log("spawning command " .. command .. " with args:")
            u.debug_log(spawn_args)
            loop.spawn(command, spawn_args, spawn_opts)
        end,
        filetypes = opts.filetypes,
        opts = opts,
        async = true,
    }
end

M.formatter_factory = function(opts)
    if opts.suppress_errors == nil then
        opts.suppress_errors = true
    end
    opts.on_output = function(params, done)
        local output = params.output
        if not output then
            return done()
        end

        return done({
            {
                row = 1,
                col = 1,
                -- source: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#range
                -- "... the end position is exclusive. If you want to specify a range that contains a line including the
                --  line ending character(s) then use an end position denoting the start of the next line."
                end_row = vim.tbl_count(params.content) + 1,
                end_col = 1,
                text = output,
            },
        })
    end

    return M.generator_factory(opts)
end

M.make_builtin = function(opts)
    local method, filetypes, factory, generator_opts, generator =
        opts.method, opts.filetypes, opts.factory, opts.generator_opts or {}, opts.generator

    local builtin = {
        method = method,
        filetypes = filetypes,
        generator = generator,
        _opts = vim.deepcopy(generator_opts),
        name = opts.name,
    }

    setmetatable(builtin, {
        __index = function(tab, key)
            return (key == "generator" and factory and factory(tab._opts)) or rawget(tab, key)
        end,
    })

    builtin.with = function(user_opts)
        builtin.filetypes = user_opts.filetypes or builtin.filetypes

        -- Extend args manually as vim.tbl_deep_extend overwrites the list
        if
            user_opts.extra_args and type(user_opts.extra_args) == "function"
            or vim.tbl_count(user_opts.extra_args) > 0
        then
            local builtin_args = builtin._opts.args
            local extra_args = user_opts.extra_args

            builtin._opts.args = function(params)
                local builtin_args_cpy = type(builtin_args) == "function" and builtin_args(params)
                    or vim.deepcopy(builtin_args)
                    or {}
                local extra_args_cpy = type(extra_args) == "function" and extra_args(params) or vim.deepcopy(extra_args)

                if builtin_args_cpy[#builtin_args_cpy] == "-" then
                    table.remove(builtin_args_cpy)
                    table.insert(extra_args_cpy, "-")
                end

                return vim.list_extend(builtin_args_cpy, extra_args_cpy)
            end
            user_opts.extra_args = nil
        end

        builtin._opts = vim.tbl_deep_extend("force", builtin._opts, user_opts)

        local condition = user_opts.condition
        if condition then
            return function()
                local should_register = condition(u.make_conditional_utils())
                if should_register then
                    u.debug_log("registering conditional source " .. builtin.name)
                    return builtin
                end

                u.debug_log("not registering conditional source " .. builtin.name)
            end
        end

        return builtin
    end

    return builtin
end

M.conditional = function(condition)
    return function()
        return condition(u.make_conditional_utils())
    end
end

M.diagnostics = (function()
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
        from_json = from_json,
    }
end)()

M.range_formatting_args_factory = function(base_args, start_arg, end_arg)
    start_arg = start_arg or "--range-start"
    end_arg = end_arg or "--range-end"

    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == methods.internal.FORMATTING then
            return args
        end

        local range = params.range

        local row, col = range.row - 1, range.col - 1
        local end_row, end_col = range.end_row - 1, range.end_col - 1

        -- neovim already takes care of offsets, so we can do this directly
        local range_start = api.nvim_buf_get_offset(params.bufnr, row) + col
        local range_end = api.nvim_buf_get_offset(params.bufnr, end_row) + end_col

        table.insert(args, start_arg)
        table.insert(args, range_start)
        table.insert(args, end_arg)
        table.insert(args, range_end)

        return args
    end
end

if _G._TEST then
    M._parse_args = parse_args
    M._json_output_wrapper = json_output_wrapper
    M._line_output_wrapper = line_output_wrapper
end

return M
