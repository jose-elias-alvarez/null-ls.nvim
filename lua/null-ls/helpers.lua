local u = require("null-ls.utils")
local c = require("null-ls.config")
local s = require("null-ls.state")
local log = require("null-ls.logger")

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
        return u.join_at_newline(params.bufnr, params.content)
    end

    -- otherwise, get content directly
    return u.buf.content(params.bufnr, true)
end

local parse_args = function(args, params)
    local vars = {
        ["FILENAME"] = function()
            return params.temp_path or params.bufname
        end,
        ["DIRNAME"] = function()
            return vim.fn.fnamemodify(params.bufname, ":h")
        end,
        ["TEXT"] = function()
            return get_content(params)
        end,
        ["FILEEXT"] = function()
            return vim.fn.fnamemodify(params.bufname, ":e")
        end,
        ["ROOT"] = function()
            return params.root
        end,
    }

    local parsed = {}
    for _, arg in ipairs(args) do
        arg = tostring(arg):gsub("$(%w+)", function(v)
            return vars[v] and vars[v]()
        end)

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
    for _, line in ipairs(u.split_at_newline(params.bufnr, output)) do
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
    local command, args, on_output, format, ignore_stderr, from_stderr, to_stdin, check_exit_code, timeout, to_temp_file, from_temp_file, use_cache, runtime_condition, cwd, dynamic_command =
        opts.command,
        opts.args,
        opts.on_output,
        opts.format,
        opts.ignore_stderr,
        opts.from_stderr,
        opts.to_stdin,
        opts.check_exit_code,
        opts.timeout,
        opts.to_temp_file,
        opts.from_temp_file,
        opts.use_cache,
        opts.runtime_condition,
        opts.cwd,
        opts.dynamic_command

    if type(check_exit_code) == "table" then
        local codes = vim.deepcopy(check_exit_code)
        check_exit_code = function(code)
            return vim.tbl_contains(codes, code)
        end
    end

    local _validated
    local validate_opts = function(params)
        validate({
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
            from_stderr = { from_stderr, "boolean", true },
            ignore_stderr = { ignore_stderr, "boolean", true },
            to_stdin = { to_stdin, "boolean", true },
            check_exit_code = { check_exit_code, "function", true },
            timeout = { timeout, "number", true },
            to_temp_file = { to_temp_file, "boolean", true },
            from_temp_file = { from_temp_file, "boolean", true },
            use_cache = { use_cache, "boolean", true },
            runtime_condition = { runtime_condition, "function", true },
            cwd = { cwd, "function", true },
            dynamic_command = { dynamic_command, "function", true },
        })

        if type(command) == "function" then
            command = command(params)
            -- prevent issues displaying / attempting to serialize generator.opts.command
            opts.command = command
        end

        if not dynamic_command then
            local is_executable, err_msg = u.is_executable(command)
            assert(is_executable, err_msg)
        end

        assert(not from_temp_file or to_temp_file, "from_temp_file requires to_temp_file to be true")

        _validated = true
    end

    return {
        fn = function(params, done)
            local loop = require("null-ls.loop")

            if not _validated then
                validate_opts(params)
            end

            local wrapper = function(error_output, output)
                log:trace("error output: " .. (error_output or "nil"))
                log:trace("output: " .. (output or "nil"))

                if ignore_stderr then
                    error_output = nil
                elseif from_stderr then
                    output = error_output
                    error_output = nil
                end

                local handle_output = function()
                    if error_output and not (format == output_formats.raw or format == output_formats.json_raw) then
                        error("error in generator output: " .. error_output)
                    end

                    params.output = params.output or output
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

                -- errors thrown from luv callbacks can't be caught
                -- so we catch them here and pass them as results
                local ok, err = pcall(handle_output)
                if not ok then
                    done({ _generator_err = err })
                end
            end

            if use_cache then
                local cached = s.get_cache(params.bufnr, command)
                if cached then
                    params._null_ls_cached = true
                    if from_stderr then
                        wrapper(cached, nil)
                    else
                        wrapper(nil, cached)
                    end
                    return
                end
            end

            local client = vim.lsp.get_client_by_id(params.client_id)
            params.root = client and client.config.root_dir or vim.fn.getcwd()
            local spawn_opts = {
                cwd = opts.cwd and opts.cwd(params) or params.root,
                input = to_stdin and get_content(params) or nil,
                handler = wrapper,
                check_exit_code = check_exit_code,
                timeout = timeout or c.get().default_timeout,
            }

            if to_temp_file then
                local filename = vim.fn.fnamemodify(params.bufname, ":e")
                local temp_path, cleanup = loop.temp_file(get_content(params), filename)

                spawn_opts.on_stdout_end = function()
                    if from_temp_file then
                        -- wrap to make sure temp file is always cleaned up
                        local ok, err = pcall(function()
                            local fd = vim.loop.fs_open(temp_path, "r", 438)
                            local stat = vim.loop.fs_fstat(fd)
                            params.output = vim.loop.fs_read(fd, stat.size, 0)
                            vim.loop.fs_close(fd)
                        end)
                        if not ok then
                            log:warn("failed to read from temp file: " .. err)
                        end
                    end

                    cleanup()
                end
                params.temp_path = temp_path
            end

            local spawn_args = args or {}
            spawn_args = type(spawn_args) == "function" and spawn_args(params) or spawn_args
            spawn_args = parse_args(spawn_args, params)

            local resolved_command = command
            if dynamic_command then
                resolved_command = dynamic_command(command, params)
            end
            if not resolved_command then
                log:debug(string.format("failed to resolve command [%s]; not spawning", command))
                return done()
            end

            opts._last_args = spawn_args
            opts._last_command = resolved_command

            log:debug(string.format("spawning command [%s] with args %s", resolved_command, vim.inspect(spawn_args)))
            loop.spawn(resolved_command, spawn_args, spawn_opts)
        end,
        filetypes = opts.filetypes,
        opts = opts,
        async = true,
    }
end

M.formatter_factory = function(opts)
    -- ignore errors unless otherwise specified
    if opts.ignore_stderr == nil then
        opts.ignore_stderr = true
    end

    -- for formatters, to_temp_file only works if from_temp_file is also set
    if opts.to_temp_file then
        opts.from_temp_file = true
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
                -- wraps to end of document
                end_row = #params.content + 1,
                end_col = 1,
                text = output,
            },
        })
    end

    return M.generator_factory(opts)
end

M.make_builtin = function(opts)
    local method, filetypes, factory, generator_opts, generator =
        opts.method, opts.filetypes, opts.factory, opts.generator_opts or {}, opts.generator or {}

    local builtin = {
        method = method,
        filetypes = filetypes,
        _opts = vim.deepcopy(generator_opts),
        name = opts.name or generator_opts.command,
    }

    factory = factory or function(_opts)
        generator.opts = _opts
        return generator
    end

    setmetatable(builtin, {
        __index = function(tab, key)
            return key == "generator" and factory(tab._opts) or rawget(tab, key)
        end,
    })

    builtin.with = function(user_opts)
        -- return a copy to allow registering multiple copies of the same built-in with different opts
        local builtin_copy = vim.deepcopy(builtin)
        setmetatable(builtin_copy, getmetatable(builtin))

        builtin_copy.filetypes = user_opts.filetypes or builtin_copy.filetypes
        builtin_copy.disabled_filetypes = user_opts.disabled_filetypes
        builtin_copy.method = user_opts.method or builtin.method

        -- set args to a function that merges args and extra_args
        if
            user_opts.extra_args
            and (type(user_opts.extra_args) == "function" or vim.tbl_count(user_opts.extra_args) > 0)
        then
            local original_args = builtin_copy._opts.args
            local original_extra_args = user_opts.extra_args

            builtin_copy._opts.args = function(params)
                local original_args_copy = type(original_args) == "function" and original_args(params)
                    or vim.deepcopy(original_args)
                    or {}
                local extra_args_copy = type(original_extra_args) == "function" and original_extra_args(params)
                    or vim.deepcopy(original_extra_args)

                -- make sure "-" stays last
                if original_args_copy[#original_args_copy] == "-" then
                    table.remove(original_args_copy)
                    table.insert(extra_args_copy, "-")
                end

                return vim.list_extend(original_args_copy, extra_args_copy)
            end
        end

        -- merge other opts with generator opts
        builtin_copy._opts = vim.tbl_deep_extend("force", builtin_copy._opts, user_opts)

        -- return a function that runs on registration to determine if source should be registered
        local condition = user_opts.condition
        if condition then
            return function()
                local should_register = condition(u.make_conditional_utils())
                if should_register then
                    log:debug("registering conditional source " .. builtin.name)
                    return builtin
                end

                log:debug("not registering conditional source " .. builtin.name)
            end
        end

        -- set a dynamic command that attempts to find a local executable on run
        local prefer_local, only_local = user_opts.prefer_local, user_opts.only_local
        -- override in case both are set
        if only_local then
            prefer_local = nil
        end

        if prefer_local or only_local then
            builtin_copy._opts.dynamic_command = function(base_command, params)
                local lsputil = require("lspconfig.util")

                -- assume the resolved command stays the same for the lifetime of the buffer,
                -- to avoid a potentially expensive search on every run
                local resolved = s.get_command(params.bufnr, base_command)
                if
                    type(resolved) == "string" -- command was resolved on last run
                    or resolved == false -- command failed to resolve, so don't bother checking again
                then
                    return resolved
                end

                local maybe_prefix = prefer_local or only_local
                local prefix = type(maybe_prefix) == "string" and maybe_prefix
                local executable_to_find = prefix and lsputil.path.join(prefix, base_command) or base_command
                log:debug("attempting to find local executable " .. executable_to_find)

                local client = u.get_client()
                local cwd = client and client.root_dir or vim.fn.getcwd()

                local local_bin
                lsputil.path.traverse_parents(params.bufname, function(dir)
                    local_bin = lsputil.path.join(dir, executable_to_find)
                    if u.is_executable(local_bin) then
                        return true
                    end

                    local_bin = nil
                    -- use cwd as a stopping point to avoid scanning the entire file system
                    if dir == cwd then
                        return true
                    end
                end)

                resolved = local_bin or (prefer_local and base_command)
                if resolved then
                    local is_executable, err_msg = u.is_executable(resolved)
                    assert(is_executable, err_msg)
                end

                s.set_command(params.bufnr, base_command, resolved or false)
                return resolved
            end
        end

        return builtin_copy
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
                return severities[entries["severity"]] or severities["_fallback"]
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
            entries[attr] = adapter(entries, content_line)
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
end)()

M.range_formatting_args_factory = function(base_args, start_arg, end_arg)
    start_arg = start_arg or "--range-start"
    end_arg = end_arg or "--range-end"

    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == require("null-ls.methods").internal.FORMATTING then
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
