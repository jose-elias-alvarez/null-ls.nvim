local c = require("null-ls.config")
local log = require("null-ls.logger")
local s = require("null-ls.state")
local u = require("null-ls.utils")

local output_formats = {
    raw = "raw", -- receive error_output and output directly
    none = nil, -- same as raw but will not send error output
    line = "line", -- call handler once per line of output
    json = "json", -- send processed json output to handler
    json_raw = "json_raw", -- attempt to process json, but send errors to handler
}

local get_content = function(params)
    -- when possible, get content from params
    if params.content then
        return u.join_at_newline(params.bufnr, params.content)
    end

    -- otherwise, get content directly
    return u.buf.content(params.bufnr, true) --[[@as string]]
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
    if params.output then
        local ok, decoded = pcall(vim.json.decode, params.output)
        if decoded == vim.NIL or decoded == "" then
            decoded = nil
        end

        if not ok then
            local error_message = "failed to decode json: " .. decoded
            if format ~= output_formats.json_raw then
                error(error_message)
            end
            params.err = error_message
        else
            params.output = decoded
        end
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
    -- normalize line endings
    output = output:gsub("\r\n?", "\n")
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

return function(opts)
    local command, args, env, on_output, format, ignore_stderr, from_stderr, to_stdin, check_exit_code, timeout, to_temp_file, from_temp_file, use_cache, runtime_condition, cwd, dynamic_command, multiple_files, temp_dir, prepend_extra_args =
        opts.command,
        opts.args,
        opts.env,
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
        opts.dynamic_command,
        opts.multiple_files,
        opts.temp_dir,
        opts.prepend_extra_args

    if type(check_exit_code) == "table" then
        local codes = check_exit_code
        check_exit_code = function(code)
            return vim.tbl_contains(codes, code)
        end
    end

    local is_nil_table_or_func = function(v)
        return v == nil or vim.tbl_contains({ "function", "table" }, type(v))
    end

    local _validated
    local validate_opts = function(params)
        local validated, validation_err = pcall(vim.validate, {
            args = { args, is_nil_table_or_func, "function or table" },
            env = { env, is_nil_table_or_func, "function or table" },
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

        if not validated then
            log:error(validation_err)
            return false
        end

        if type(command) == "function" then
            command = command(params)
            -- prevent issues displaying / attempting to serialize generator.opts.command
            opts.command = command
        end

        return true
    end

    return {
        fn = function(params, done)
            local loop = require("null-ls.loop")

            local original_done = done
            local done_called = false
            done = function(...)
                -- plenary will throw an error if its async callback is called more than once
                if done_called then
                    return
                end
                done_called = true
                original_done(...)
            end

            local root = u.get_root()
            params.root = root

            if not _validated then
                local validated = validate_opts(params)
                if not validated then
                    done({ _should_deregister = true })
                    return
                end

                _validated = true
            end

            local wrapper = function(error_output, output)
                log:trace("error output: " .. (error_output or "nil"))
                log:trace("output: " .. (output or "nil"))

                if ignore_stderr then
                    if error_output then
                        log:trace("ignoring stderr due to generator options")
                    end
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
                    opts._last_output = output or ""

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

                -- errors thrown from luv callbacks can't be caught,
                -- so we catch them here and pass them as results
                local ok, err = pcall(handle_output)
                if not ok then
                    done({ _generator_err = err })
                    return
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

            params.command = command

            local resolved_command
            if dynamic_command then
                resolved_command = dynamic_command(params)
            else
                resolved_command = command
            end

            -- if dynamic_command returns nil, don't fall back to command
            if not resolved_command then
                log:debug(string.format("unable to resolve command %s; aborting", command))
                return done()
            end

            local resolved_cwd = cwd and cwd(params) or root
            params.cwd = resolved_cwd

            if type(env) == "function" then
                env = env(params)
            end

            local spawn_opts = {
                cwd = resolved_cwd,
                input = to_stdin and get_content(params) or nil,
                handler = wrapper,
                check_exit_code = check_exit_code,
                timeout = timeout or c.get().default_timeout,
                env = env,
            }

            if to_temp_file then
                local content = get_content(params)
                local temp_path, cleanup = loop.temp_file(content, params.bufname, temp_dir or c.get().temp_dir)

                spawn_opts.on_stdout_end = function()
                    if from_temp_file then
                        params.output = loop.read_file(temp_path)
                    end
                    cleanup()
                end
                params.temp_path = temp_path
            end

            local resolved_args = args or {}
            resolved_args = type(resolved_args) == "function" and resolved_args(params) or resolved_args
            resolved_args = parse_args(resolved_args, params)

            opts._last_command = resolved_command
            opts._last_args = resolved_args
            opts._last_cwd = resolved_cwd

            log:debug(
                string.format(
                    "spawning command %s at %s with args %s",
                    vim.inspect(resolved_command),
                    resolved_cwd,
                    vim.inspect(resolved_args)
                )
            )
            loop.spawn(resolved_command, resolved_args, spawn_opts)
        end,
        filetypes = opts.filetypes,
        opts = opts,
        async = true,
        multiple_files = multiple_files,
        prepend_extra_args = prepend_extra_args,
    }
end
