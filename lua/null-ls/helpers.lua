local u = require("null-ls.utils")
local c = require("null-ls.config")
local s = require("null-ls.state")
local loop = require("null-ls.loop")

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
    local command, args, on_output, format, to_stderr, to_stdin, ignore_errors, check_exit_code, timeout, to_temp_file, use_cache =
        opts.command,
        opts.args,
        opts.on_output,
        opts.format,
        opts.to_stderr,
        opts.to_stdin,
        opts.ignore_errors,
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
            command = { command, "string" },
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
            ignore_errors = { ignore_errors, "boolean", true },
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
                    if not ignore_errors then
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
                bufnr = params.bufnr,
                check_exit_code = check_exit_code,
                timeout = timeout or c.get().default_timeout,
            }

            if to_temp_file then
                local temp_path, cleanup = loop.temp_file(get_content(params))

                spawn_args = u.table.replace(spawn_args, "$FILENAME", temp_path)
                spawn_opts.on_stdout_end = cleanup
            end

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
    if opts.ignore_errors == nil then
        opts.ignore_errors = true
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
        opts.method, opts.filetypes, opts.factory, opts.generator_opts, opts.generator

    local builtin = {
        method = method,
        filetypes = filetypes,
        generator = generator,
        _opts = generator_opts or {},
        name = opts.name,
    }

    setmetatable(builtin, {
        __index = function(tab, key)
            return (key == "generator" and factory and factory(tab._opts)) or rawget(tab, key)
        end,
    })

    builtin.with = function(user_opts)
        builtin.filetypes = user_opts.filetypes or builtin.filetypes
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

if _G._TEST then
    M._json_output_wrapper = json_output_wrapper
    M._line_output_wrapper = line_output_wrapper
end

return M
