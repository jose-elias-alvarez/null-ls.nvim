local stub = require("luassert.stub")
local mock = require("luassert.mock")

local u = require("null-ls.utils")

local uv = mock(vim.loop, true)

describe("loop", function()
    stub(vim, "schedule_wrap")
    after_each(function()
        vim.schedule_wrap:clear()
        uv.os_environ.returns({})
    end)

    local loop = require("null-ls.loop")

    describe("spawn", function()
        local mock_cmd = "cat"
        local mock_args = { "-n" }
        local mock_handler = stub.new()
        local check_exit_code = stub.new()

        local mock_handle = {}
        local mock_handle_is_closing = stub.new()
        local mock_handle_close = stub.new()
        local mock_stdin = {}
        local mock_stdin_write = stub.new()
        local mock_stdin_is_closing = stub.new()
        local mock_stdin_close = stub.new()
        local mock_stdin_shutdown = stub.new()
        local mock_stdout = {}
        local mock_stdout_read_stop = stub.new()
        local mock_stdout_is_closing = stub.new()
        local mock_stdout_close = stub.new()
        local mock_stderr = {}
        local mock_stderr_read_stop = stub.new()
        local mock_stderr_is_closing = stub.new()
        local mock_stderr_close = stub.new()

        local mock_opts
        before_each(function()
            check_exit_code.returns(true)
            mock_opts = {
                handler = function(...)
                    mock_handler(...)
                end,
                check_exit_code = check_exit_code,
            }

            function mock_stdin:write(...)
                mock_stdin_write(...)
            end
            function mock_stdin:is_closing()
                return mock_stdin_is_closing()
            end
            function mock_stdin:close()
                mock_stdin_close()
            end
            function mock_stdin:shutdown(...)
                mock_stdin_shutdown(...)
            end
            function mock_handle:is_closing()
                return mock_handle_is_closing()
            end
            function mock_handle:close()
                mock_handle_close()
            end
            function mock_stdout:read_stop()
                mock_stdout_read_stop()
            end
            function mock_stdout:is_closing()
                return mock_stdout_is_closing()
            end
            function mock_stdout:close()
                mock_stdout_close()
            end
            function mock_stderr:read_stop()
                mock_stderr_read_stop()
            end
            function mock_stderr:is_closing()
                return mock_stderr_is_closing()
            end
            function mock_stderr:close()
                mock_stderr_close()
            end
        end)

        after_each(function()
            mock_handler:clear()
            mock_stdin_write:clear()
            mock_stdin_close:clear()
            mock_stdin_shutdown:clear()
            mock_handle_is_closing:clear()
            mock_handle_close:clear()
            mock_stdout_read_stop:clear()
            mock_stdout_is_closing:clear()
            mock_stdout_close:clear()
            mock_stderr_read_stop:clear()
            mock_stderr_is_closing:clear()
            mock_stderr_close:clear()

            uv.spawn:clear()
            uv.read_start:clear()
            uv.new_pipe:clear()
        end)

        it("should call uv.spawn with cmd and args", function()
            loop.spawn(mock_cmd, mock_args, mock_opts)

            assert.stub(uv.spawn).was_called()
            assert.equals(uv.spawn.calls[1].refs[1], vim.fn.exepath(mock_cmd))
            assert.same(uv.spawn.calls[1].refs[2].args, mock_args)
        end)

        it("should parse user env vars", function()
            local key = "TEST"
            local value = "TESTING"
            local options = { env = { [key] = value } }
            -- environment variables are converted from a dict to key-value pair table
            local expected = key .. "=" .. value

            loop.spawn(mock_cmd, mock_args, options)

            local env = uv.spawn.calls[1].refs[2].env
            assert.equals(#env, 1)
            assert.truthy(vim.tbl_contains(env, expected))
        end)

        it("should merge user env vars with os env", function()
            local key = "TEST"
            local value = "TESTING"
            local options = { env = { [key] = value } }
            uv.os_environ.returns({ OS_KEY = "OS_VAL" })

            local expected = "OS_KEY" .. "=" .. "OS_VAL"

            loop.spawn(mock_cmd, mock_args, options)

            local env = uv.spawn.calls[1].refs[2].env
            assert.equals(#env, 2)
            assert.truthy(vim.tbl_contains(env, expected))
        end)

        it("should call uv.read_start twice", function()
            loop.spawn(mock_cmd, mock_args, mock_opts)

            assert.stub(uv.read_start).was_called(2)
        end)

        it("should allow a table for cmd", function()
            loop.spawn({ "cat", "-b" }, { "-n" }, mock_opts)

            assert.equals(uv.spawn.calls[1].refs[1], vim.fn.exepath("cat"))
            assert.same(uv.spawn.calls[1].refs[2].args, { "-b", "-n" })
        end)

        describe("stdin", function()
            local mock_input = "I have content"
            before_each(function()
                uv.new_pipe.returns(mock_stdin)
            end)

            it("should call stdin:write when input is given", function()
                mock_opts.input = mock_input

                loop.spawn(mock_cmd, mock_args, mock_opts)

                assert.stub(mock_stdin_write).was_called()
                assert.equals(mock_stdin_write.calls[1].refs[1], mock_input)
            end)

            it("should call stdin:write with input", function()
                mock_opts.input = mock_input

                loop.spawn(mock_cmd, mock_args, mock_opts)

                assert.stub(mock_stdin_write).was_called_with(mock_input)
            end)

            it("should call stdin:shutdown with close callback", function()
                mock_opts.input = mock_input
                loop.spawn(mock_cmd, mock_args, mock_opts)

                assert.stub(mock_stdin_shutdown).was_called()
                local callback = mock_stdin_shutdown.calls[1].refs[1]
                callback()

                assert.stub(mock_stdin_close).was_called()
            end)
        end)

        describe("handle_stdout", function()
            local handle_stdout
            before_each(function()
                loop.spawn(mock_cmd, mock_args, mock_opts)
                handle_stdout = uv.read_start.calls[1].refs[2]
            end)

            it("should throw error if err is passed in", function()
                assert.has_error(function()
                    handle_stdout("error", nil)
                end)
            end)

            it("should append chunks to output", function()
                handle_stdout(nil, "chunk1")
                handle_stdout(nil, "chunk2")
                handle_stdout(nil, nil)

                local done = vim.schedule_wrap.calls[1].refs[1]
                done(true)

                local output = mock_handler.calls[1].refs[2]

                assert.equals(output, "chunk1chunk2")
            end)
        end)

        describe("handle_stderr", function()
            local handle_stderr
            before_each(function()
                loop.spawn(mock_cmd, mock_args, mock_opts)
                handle_stderr = uv.read_start.calls[2].refs[2]
            end)

            it("should throw error if err is passed in", function()
                assert.has_error(function()
                    handle_stderr("error", nil)
                end)
            end)

            it("should append chunks to error_output", function()
                handle_stderr(nil, "errorchunk1")
                handle_stderr(nil, "errorchunk2")

                local handle_stdout = vim.schedule_wrap.calls[1].refs[1]
                handle_stdout(nil, nil)

                local error_output = mock_handler.calls[1].refs[1]
                assert.equals(error_output, "errorchunk1errorchunk2")
            end)
        end)

        describe("done", function()
            local handle_stdout
            before_each(function()
                loop.spawn(mock_cmd, mock_args, mock_opts)
                handle_stdout = uv.read_start.calls[1].refs[2]
            end)

            it("should set output to nil if empty string", function()
                handle_stdout(nil, "")
                handle_stdout(nil, nil)

                local done = vim.schedule_wrap.calls[1].refs[1]
                done(true)

                local output = mock_handler.calls[1].refs[2]
                assert.equals(output, nil)
            end)

            it("should set error_output to nil if empty string", function()
                handle_stdout(nil, "")
                handle_stdout(nil, nil)

                local done = vim.schedule_wrap.calls[1].refs[1]
                done(true)

                local error_output = mock_handler.calls[1].refs[1]
                assert.equals(error_output, nil)
            end)

            it("should swap output and error_output if exit_ok is false", function()
                handle_stdout(nil, "bad")
                handle_stdout(nil, nil)

                local done = vim.schedule_wrap.calls[1].refs[1]
                done(false)

                assert.stub(mock_handler).was_called_with("bad", nil)
            end)
        end)

        describe("on_close", function()
            local done = stub.new()
            before_each(function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
                vim.schedule_wrap.returns(done)
            end)
            after_each(function()
                check_exit_code:clear()
                done:clear()
            end)

            it("should call done with exit and timeout results", function()
                mock_opts.check_exit_code = nil
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)

                assert.stub(done).was_called_with(true, false)
            end)

            it("should only call done once", function()
                mock_opts.check_exit_code = nil
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)
                on_close(0)

                assert.stub(done).was_called(1)
            end)

            it("should check that code is 0 when check_exit_code is nil", function()
                mock_opts.check_exit_code = nil
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(255)

                assert.stub(check_exit_code).was_not_called()
                assert.stub(done).was_called_with(false, false)
            end)

            it("should check exit code with check_exit_code callback", function()
                check_exit_code.returns(false)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(255)

                assert.stub(check_exit_code).was_called_with(255, "")
                assert.stub(done).was_called_with(false, false)
            end)

            it("should set did_timeout if exit code is TIMEOUT_EXIT_CODE", function()
                mock_opts.check_exit_code = nil
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(7451)

                assert.stub(check_exit_code).was_not_called()
                assert.stub(done).was_called_with(false, true)
            end)

            it("should call close_handle on spawn handle", function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)

                assert.stub(mock_handle_is_closing).was_called()
                assert.stub(mock_handle_close).was_called()
            end)

            it("should not call close_handle if is_closing returns true", function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
                mock_handle_is_closing.returns(true)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)

                assert.stub(mock_handle_is_closing).was_called()
                assert.stub(mock_handle_close).was_not_called()
            end)

            it("should call read_stop and close_handle on stdout handle", function()
                uv.new_pipe.returns(mock_stdout)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)

                assert.stub(mock_stdout_read_stop).was_called()
                assert.stub(mock_stdout_is_closing).was_called()
                assert.stub(mock_stdout_close).was_called()
            end)

            it("should call read_stop and close_handle on stderr handle", function()
                uv.new_pipe.returns(mock_stderr)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local on_close = uv.spawn.calls[1].refs[3]
                on_close(0)

                assert.stub(mock_stderr_read_stop).was_called()
                assert.stub(mock_stderr_is_closing).was_called()
                assert.stub(mock_stderr_close).was_called()
            end)
        end)

        describe("timeout", function()
            local timer = { stop = stub.new() }
            local mock_done = stub.new()
            local timeout = 500
            before_each(function()
                stub(loop, "timer")
                loop.timer.returns(timer)
                vim.schedule_wrap.returns(mock_done)

                mock_opts.timeout = timeout
                loop.spawn(mock_cmd, mock_args, mock_opts)
            end)
            after_each(function()
                timer.stop:clear()
                mock_done:clear()
                loop.timer:revert()
            end)

            it("should create timer when timeout is set", function()
                assert.stub(loop.timer).was_called()
                assert.equals(loop.timer.calls[1].refs[1], timeout)
                assert.equals(loop.timer.calls[1].refs[2], nil)
                assert.equals(loop.timer.calls[1].refs[3], true)
            end)

            it("should call on_close and timer.stop on timer callback", function()
                local callback = loop.timer.calls[1].refs[4]

                callback()

                assert.stub(mock_done).was_called()
                assert.stub(timer.stop).was_called_with(true)
            end)

            it("should call timer.stop() in done", function()
                local done = vim.schedule_wrap.calls[1].refs[1]

                done(true)

                assert.stub(timer.stop).was_called_with(true)
            end)

            it("should not create a timer when timeout value is less than zero", function()
                loop.timer:clear()

                loop.spawn(mock_cmd, mock_args, vim.tbl_extend("force", mock_opts, { timeout = -1 }))

                assert.stub(loop.timer).was_not_called()
            end)
        end)
    end)

    describe("timer", function()
        local mock_timer = {}
        local start = stub.new()
        local stop = stub.new()
        local close = stub.new()
        local is_closing = stub.new()
        function mock_timer:start(...)
            start(...)
        end
        function mock_timer:stop()
            stop()
        end
        function mock_timer:close()
            close()
        end
        function mock_timer:is_closing()
            is_closing()
        end

        local timeout = 10
        local interval = 5
        local callback = stub.new()
        local _callback = function()
            callback()
        end

        before_each(function()
            uv.new_timer.returns(mock_timer)
            vim.schedule_wrap.returns("wrapped")
        end)
        after_each(function()
            callback:clear()
            start:clear()
            stop:clear()
            close:clear()
            is_closing:clear()
        end)

        it("should return object with methods and original timer", function()
            local timer = loop.timer(timeout, interval, false, _callback)

            assert.truthy(timer.start)
            assert.truthy(timer.stop)
            assert.truthy(timer.restart)
            assert.truthy(timer.stop)
            assert.equals(timer._timer, mock_timer)
        end)

        it("should pass callback to schedule_wrap", function()
            loop.timer(timeout, interval, false, _callback)

            vim.schedule_wrap.calls[1].refs[1]()

            assert.stub(callback).was_called()
        end)

        it("should default interval to 0 when nil", function()
            local timer = loop.timer(timeout, nil, false, _callback)

            timer.start()

            assert.stub(start).was_called_with(timeout, 0, "wrapped")
        end)

        it("should start timer when should_start = true", function()
            loop.timer(timeout, nil, true, _callback)

            assert.stub(start).was_called_with(timeout, 0, "wrapped")
        end)

        describe("methods", function()
            local timer
            before_each(function()
                timer = loop.timer(timeout, interval, false, _callback)
            end)

            describe("start", function()
                it("should call timer:start method", function()
                    timer.start()

                    assert.stub(start).was_called_with(timeout, interval, "wrapped")
                end)
            end)

            describe("close", function()
                it("should call close_handle on timer", function()
                    timer.close()

                    assert.stub(is_closing).was_called()
                    assert.stub(close).was_called()
                end)
            end)

            describe("stop", function()
                it("should call timer:stop method", function()
                    timer.stop()

                    assert.stub(stop).was_called_()
                end)

                it("should also call close() when should_close is true", function()
                    timer.stop(true)

                    assert.stub(stop).was_called_()
                    assert.stub(is_closing).was_called()
                    assert.stub(close).was_called()
                end)
            end)

            describe("restart", function()
                it("should restart timer with original interval and wrapped callback", function()
                    timer.restart()

                    assert.stub(stop).was_called()
                    assert.stub(start).was_called_with(timeout, interval, "wrapped")
                end)

                it("should restart timer with new timeout and interval", function()
                    local new_timeout = 100
                    local new_interval = 99

                    timer.restart(new_timeout, new_interval)

                    assert.stub(stop).was_called()
                    assert.stub(start).was_called_with(new_timeout, new_interval, "wrapped")
                end)
            end)
        end)
    end)

    describe("temp_file", function()
        local mock_content = "write me to a temp file"
        local mock_fd, mock_path = 57, "/tmp/null-ls-123456"

        local fs_mkstemp = uv.fs_mkstemp
        local tmpname
        before_each(function()
            u.path.is_windows = false

            tmpname = stub(os, "tmpname")

            tmpname.returns(mock_path)
            uv.fs_mkstemp.returns(mock_fd, mock_path)
            uv.fs_open.returns(mock_fd)
        end)
        after_each(function()
            tmpname:revert()
            uv.fs_write:clear()
            uv.fs_close:clear()
            uv.fs_unlink:clear()
            uv.fs_mkstemp = fs_mkstemp
            uv.fs_mkstemp:clear()
            uv.fs_rename:clear()
        end)

        it("should call uv.fs_mkstemp with path + pattern", function()
            loop.temp_file(mock_content)

            assert.stub(uv.fs_mkstemp).was_called_with("/tmp/null-ls_XXXXXX")
        end)

        it("should not call uv.fs_open if fd from fs_mkstemp is already open", function()
            loop.temp_file(mock_content)

            assert.stub(uv.fs_open).was_not_called()
        end)

        it("should call os.tmpname if no uv.fs_mkstemp", function()
            uv.fs_mkstemp = nil

            loop.temp_file(mock_content)

            assert.stub(tmpname).was_called()
        end)

        it("should call uv.fs_open with path and permissions", function()
            loop.temp_file(mock_content)

            assert.stub(uv.fs_open).was_called_with(mock_path, "w", 384)
        end)

        describe("extension", function()
            local mock_extension = "lua"

            it("should call uv.fs_close on original handle", function()
                local original_handle = 19
                uv.fs_mkstemp.returns(original_handle, mock_path)

                loop.temp_file(mock_content, mock_extension)

                assert.stub(uv.fs_close).was_called_with(original_handle)
            end)

            it("should set original handle to nil and get new handle from fs_open", function()
                local original_handle = 19
                uv.fs_mkstemp.returns(original_handle, mock_path)

                loop.temp_file(mock_content, mock_extension)

                assert.stub(uv.fs_open).was_called()
            end)

            it("should call fs_rename with original path and path with extension", function()
                loop.temp_file(mock_content, mock_extension)

                assert.stub(uv.fs_rename).was_called_with(mock_path, mock_path .. ".lua")
            end)

            it("should set tmp_path to path with extension", function()
                loop.temp_file(mock_content, mock_extension)

                assert.stub(uv.fs_open).was_called_with(mock_path .. ".lua", "w", 384)
            end)
        end)

        it("should call fs_write and fs_close with fd and content", function()
            loop.temp_file(mock_content)

            assert.stub(uv.fs_write).was_called_with(mock_fd, mock_content, -1)
            assert.stub(uv.fs_close).was_called_with(mock_fd)
        end)

        it("should return tmp_path", function()
            local path = loop.temp_file(mock_content)

            assert.equals(path, mock_path)
        end)

        it("should call fs_unlink with path on callback", function()
            local _, callback = loop.temp_file(mock_content)

            callback()

            assert.stub(uv.fs_unlink).was_called_with(mock_path)
        end)

        describe("windows", function()
            local getenv = stub(vim.fn, "getenv")
            local windows_temp_dir = "C:\\temp"

            before_each(function()
                getenv.returns(windows_temp_dir)
            end)
            after_each(function()
                getenv:clear()
            end)

            it("should get TEMP env var", function()
                u.path.is_windows = true

                loop.temp_file(mock_content)

                assert.stub(getenv).was_called_with("TEMP")
            end)

            it("should call uv.fs_mkstemp with path + pattern", function()
                u.path.is_windows = true

                loop.temp_file(mock_content)

                assert.stub(uv.fs_mkstemp).was_called_with(u.path.join(windows_temp_dir, "null-ls_XXXXXX"))
            end)
        end)
    end)
end)
