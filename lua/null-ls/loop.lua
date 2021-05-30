local u = require("null-ls.utils")

local api = vim.api
local uv = vim.loop
local wrap = vim.schedule_wrap

local close_handle = function(handle)
    if handle and not handle:is_closing() then
        handle:close()
    end
end

local parse_args = function(args, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local parsed = {}
    for _, arg in pairs(args) do
        if string.find(arg, "$FILENAME") then
            arg = u.string.replace(arg, "$FILENAME", api.nvim_buf_get_name(bufnr))
        end
        if string.find(arg, "$TEXT") then
            arg = u.string.replace(arg, "$TEXT", u.buf.content(bufnr, true))
        end

        table.insert(parsed, arg)
    end
    return parsed
end

local TIMEOUT_EXIT_CODE = 7451

local M = {}

M.spawn = function(cmd, args, opts)
    local handler, input, bufnr, check_exit_code, timeout, on_stdout_end =
        opts.handler, opts.input, opts.bufnr, opts.check_exit_code, opts.timeout, opts.on_stdout_end

    local timer
    local output, error_output, exit_ok = "", "", _G._TEST and true or nil
    local handle_stdout = wrap(function(err, chunk)
        if err then
            error("stdout error: " .. err)
        end

        if chunk then
            output = output .. chunk
        end
        if not chunk then
            if timer then
                timer.stop(true)
            end

            -- wait for handler callback to check exit code
            vim.wait(500, function()
                return exit_ok ~= nil
            end, 10)

            -- convert empty strings to make nil checks easier
            if output == "" then
                output = nil
            end
            if error_output == "" then
                error_output = nil
            end

            -- if exit code is not ok and program did not output to stderr,
            -- assign output to error_output, so handler can process it as an error
            if not exit_ok and not error_output then
                error_output = output
                output = nil
            end

            handler(error_output, output)
        end
    end)

    local handle_stderr = function(err, chunk)
        if err then
            error("stderr error: " .. err)
        end

        if chunk then
            error_output = error_output .. chunk
        end
    end

    local stdin = uv.new_pipe(true)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local stdio = { stdin, stdout, stderr }

    local handle
    local close = wrap(function(code)
        if code == TIMEOUT_EXIT_CODE then
            exit_ok = false
        else
            exit_ok = check_exit_code and check_exit_code(code) or code == 0
        end

        stdout:read_stop()
        stderr:read_stop()
        if on_stdout_end then
            on_stdout_end()
        end

        close_handle(stdin)
        close_handle(stdout)
        close_handle(stderr)
        close_handle(handle)
    end)

    handle = uv.spawn(cmd, { args = parse_args(args, bufnr), stdio = stdio }, close)
    if timeout then
        timer = M.timer(timeout, nil, true, function()
            close(TIMEOUT_EXIT_CODE)
            handler()
            timer.stop(true)
        end)
    end

    uv.read_start(stdout, handle_stdout)
    uv.read_start(stderr, handle_stderr)

    if input then
        stdin:write(input, function()
            stdin:close()
        end)
    end
end

M.timer = function(timeout, interval, should_start, callback)
    interval = interval or 0

    local timer = uv.new_timer()
    local wrapped = wrap(callback)

    local start = function()
        timer:start(timeout, interval, wrapped)
    end
    local close = function()
        close_handle(timer)
    end
    local stop = function(should_close)
        timer:stop()
        if should_close then
            close()
        end
    end
    local restart = function(new_timeout, new_interval)
        timer:stop()
        timer:start(new_timeout or timeout, new_interval or interval, wrapped)
    end

    if should_start then
        timer:start(timeout, interval, wrapped)
    end
    return {
        _timer = timer,
        start = start,
        stop = stop,
        restart = restart,
        close = close,
    }
end

M.temp_file = function(content)
    local fd, tmp_path = uv.fs_mkstemp("/tmp/null-ls-XXXXXX")

    uv.fs_write(fd, content)
    uv.fs_close(fd)

    return tmp_path, function()
        uv.fs_unlink(tmp_path)
    end
end

if _G._TEST then
    M._parse_args = parse_args
    M._TIMEOUT_EXIT_CODE = TIMEOUT_EXIT_CODE
end

return M
