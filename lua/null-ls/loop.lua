local log = require("null-ls.logger")
local u = require("null-ls.utils")

local uv = vim.loop
local wrap = vim.schedule_wrap

local close_handle = function(handle)
    if handle and not handle:is_closing() then
        handle:close()
    end
end

local on_error = function(errkind, ...)
    log:debug(string.format("[%q] has failed with: %q", errkind, table.concat(..., ", ")))
    -- we need to make sure to raise an error
    error(string.format("[%q] has failed with: %q", errkind, table.concat(..., ", ")))
end

---@private
--- Merges current process env with the given env and returns the result as
--- a list of "k=v" strings.
---
--- <pre>
--- Example:
---
---  in:    { PRODUCTION="false", PATH="/usr/bin/", PORT=123, HOST="0.0.0.0", }
---  out:   { "PRODUCTION=false", "PATH=/usr/bin/", "PORT=123", "HOST=0.0.0.0", }
--- </pre>
---@param env table table of environment variable assignments
---@return table merged list of `"k=v"` strings
local function env_merge(env)
    -- Merge.
    env = vim.tbl_extend("force", uv.os_environ(), env)

    local final_env = {}
    for k, v in pairs(env) do
        table.insert(final_env, k .. "=" .. tostring(v))
    end

    return final_env
end

local TIMEOUT_EXIT_CODE = 7451

local M = {}

M.spawn = function(cmd, args, opts)
    local handler, input, check_exit_code, timeout, on_stdout_end, env =
        opts.handler, opts.input, opts.check_exit_code, opts.timeout, opts.on_stdout_end, opts.env

    local output, error_output = "", ""
    local handle_stdout = function(err, chunk)
        if err then
            on_error("stdout", err)
        end
        if chunk then
            output = output .. chunk
        end
    end

    local handle_stderr = function(err, chunk)
        if err then
            on_error("stderr", err)
        end
        if chunk then
            error_output = error_output .. chunk
        end
    end

    local timer
    local done = wrap(function(exit_ok, did_timeout)
        if timer then
            timer.stop(true)
        end

        -- convert empty strings to make nil checks easier
        if output == "" then
            output = nil
        end
        if error_output == "" then
            error_output = nil
        end

        -- if exit code is not ok and command did not output to stderr,
        -- assign output to error_output, so handler can process it as an error
        if not did_timeout and not exit_ok and not error_output then
            error_output = output
            output = nil
        end

        handler(error_output, output)
    end)

    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local stdio = { stdin, stdout, stderr }

    local handle
    local on_close = function(code)
        if not handle then
            return
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

        local exit_ok
        if code == TIMEOUT_EXIT_CODE then
            exit_ok = false
        elseif check_exit_code then
            exit_ok = check_exit_code(code, error_output)
        else
            exit_ok = code == 0
        end

        done(exit_ok, code == TIMEOUT_EXIT_CODE)
        handle = nil
    end

    local parsed_env = nil
    if env and not vim.tbl_isempty(env) then
        parsed_env = env_merge(env)
    end

    if type(cmd) == "table" then
        local concat_args = {}
        for i = 2, #cmd do
            concat_args[#concat_args + 1] = cmd[i]
        end
        for _, arg in ipairs(args) do
            concat_args[#concat_args + 1] = arg
        end
        cmd, args = cmd[1], concat_args
    end

    handle = uv.spawn(
        vim.fn.exepath(cmd),
        { args = args, env = parsed_env, stdio = stdio, cwd = opts.cwd or vim.fn.getcwd() },
        on_close
    )

    if timeout and timeout > 0 then
        timer = M.timer(timeout, nil, true, function()
            log:debug(string.format("command [%s] timed out after %s ms", cmd, timeout))
            on_close(TIMEOUT_EXIT_CODE)
            timer.stop(true)
        end)
    end

    uv.read_start(stdout, handle_stdout)
    uv.read_start(stderr, handle_stderr)

    if input then
        stdin:write(input)
        stdin:shutdown(function()
            close_handle(stdin)
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

M.temp_file = function(content, extension)
    local tmp_dir = u.path.is_windows and vim.fn.getenv("TEMP") or "/tmp"

    local fd, tmp_path
    if uv.fs_mkstemp then
        -- prefer fs_mkstemp, since we can modify the directory
        fd, tmp_path = uv.fs_mkstemp(u.path.join(tmp_dir, "null-ls_XXXXXX"))
    else
        -- fall back to os.tmpname, which is Unix-only
        tmp_path = os.tmpname()
    end

    -- close handle if open and rename temp file to add extension
    if extension then
        if fd then
            uv.fs_close(fd)
            fd = nil
        end

        local path_with_ext = tmp_path .. "." .. extension
        uv.fs_rename(tmp_path, path_with_ext)
        tmp_path = path_with_ext
    end

    -- if not open, open with (0700) permissions
    fd = fd or uv.fs_open(tmp_path, "w", 384)
    uv.fs_write(fd, content, -1)
    uv.fs_close(fd)

    return tmp_path, function()
        uv.fs_unlink(tmp_path)
    end
end

---@param path string
---@param txt string
---@param flag string|number
M.write_file = function(path, txt, flag)
    uv.fs_open(path, flag, 438, function(open_err, fd)
        assert(not open_err, open_err)
        uv.fs_write(fd, txt, -1, function(write_err)
            assert(not write_err, write_err)
            uv.fs_close(fd, function(close_err)
                assert(not close_err, close_err)
            end)
        end)
    end)
end
return M
