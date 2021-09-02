local u = require("null-ls.utils")

local uv = vim.loop
local wrap = vim.schedule_wrap

local close_handle = function(handle)
    if handle and not handle:is_closing() then
        handle:close()
    end
end

local M = {}

M.spawn = function(command, args, opts)
    local handler, input, check_exit_code, timeout, on_stdout_end =
        opts.handler, opts.input, opts.check_exit_code, opts.timeout, opts.on_stdout_end

    local output, error_output = {}, {}
    local on_stdout = function(err, data)
        if err then
            error("stdout error: " .. err)
        end
        table.insert(output, data)
    end
    local on_stderr = function(err, data)
        if err then
            error("stderr error: " .. err)
        end
        table.insert(error_output, data)
    end

    local on_exit = wrap(function(_, code)
        if vim.o.eol then
            table.insert(output, "")
            table.insert(error_output, "")
        end

        output = table.concat(output, "\n")
        error_output = table.concat(error_output, "\n")

        -- convert empty strings to make nil checks easier
        if output == "" then
            output = nil
        end
        if error_output == "" then
            error_output = nil
        end

        -- if exit code is not ok and command did not output to stderr,
        -- assign output to error_output, so handler can process it as an error
        local exit_ok = check_exit_code and check_exit_code(code) or code == 0
        if not exit_ok and not error_output then
            error_output = output
            output = nil
        end

        handler(error_output, output)
    end)

    local job = require("plenary.job"):new({
        command = command,
        args = args,
        cwd = opts.cwd or vim.fn.getcwd(),
        writer = input,
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit,
    })

    if timeout then
        local timer = M.timer(timeout, nil, true, function()
            u.debug_log("command timed out after " .. timeout .. " ms")
            job:shutdown()
        end)

        job:add_on_exit_callback(function()
            timer.stop(true)
        end)
    end

    if on_stdout_end then
        job:add_on_exit_callback(on_stdout_end)
    end

    job:start()
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
    local tmp_path = os.tmpname()
    local fd = uv.fs_open(tmp_path, "w", 0)
    uv.fs_write(fd, content, -1)
    uv.fs_close(fd)

    return tmp_path, function()
        uv.fs_unlink(tmp_path)
    end
end

return M
