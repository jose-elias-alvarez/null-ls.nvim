local log = require("null-ls.logger")
local u = require("null-ls.utils")

local uv = vim.loop
local wrap = vim.schedule_wrap --[[@as fun(cb: any): function]]

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

    local output, error_output
    output, error_output = "", ""
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

    local handle, pid
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

    local exepath = vim.fn.exepath(cmd)
    local spawn_params = {
        args = args,
        env = parsed_env,
        stdio = stdio,
        cwd = opts.cwd or vim.loop.cwd(),
    }

    handle, pid = uv.spawn(
        exepath ~= "" and exepath or cmd, -- if we can't resolve exepath, try spawning the command as-is
        spawn_params,
        on_close
    )

    if not handle then
        local message = pid:match("ENOENT")
                and string.format("command %s is not executable (make sure it's installed and on your $PATH)", cmd)
            or string.format("failed to spawn command %s: %s", cmd, pid)
        error(message)
    end

    if timeout and timeout > 0 then
        timer = M.timer(timeout, nil, true, function()
            log:debug(string.format("command %s timed out after %s ms", cmd, timeout))

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

--- creates a temp file at a given file's location
---@param content string
---@param bufname string
---@param dirname string|nil
---@return string temp_path, fun() cleanup
M.temp_file = function(content, bufname, dirname)
    dirname = dirname or vim.fn.fnamemodify(bufname, ":h")
    local base_name = vim.fn.fnamemodify(bufname, ":t")

    local filename = string.format(".null-ls_%d_%s", math.random(100000, 999999), base_name)
    local temp_path = u.path.join(dirname, filename)

    local fd, err = uv.fs_open(temp_path, "w", 384)
    if not fd then
        error("failed to create temp file: " .. err)
    end

    uv.fs_write(fd, content, -1)
    uv.fs_close(fd)

    local autocmd_id
    local cleanup = function()
        if not temp_path then
            return
        end

        uv.fs_unlink(temp_path)
        temp_path = nil

        if autocmd_id then
            vim.schedule(function()
                vim.api.nvim_del_autocmd(autocmd_id)
            end)
        end
    end

    -- make sure to run cleanup on exit
    autocmd_id = vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = cleanup,
    })

    return temp_path, cleanup
end

--- read from file at path
---@param path string
---@return string content
M.read_file = function(path)
    local content
    local ok, err = pcall(function()
        local fd = uv.fs_open(path, "r", 438)
        local stat = uv.fs_fstat(fd)
        content = uv.fs_read(fd, stat.size, 0)
        uv.fs_close(fd)
    end)

    if not ok then
        log:error(string.format("failed to read from file at %s: %s ", path, err))
    end

    return content or ""
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
