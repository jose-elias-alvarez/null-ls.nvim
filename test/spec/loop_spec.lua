local stub = require("luassert.stub")
local mock = require("luassert.mock")

local test_utils = require("test.utils")

describe("loop", function()
    _G._TEST = true
    local loop = require("null-ls.loop")
    local uv = mock(vim.loop, true)

    describe("parse_args", function()
        it("should replace $FILENAME with buffer name", function()
            local args = {"--stdin-filename", "$FILENAME"}
            test_utils.edit_test_file("test-file.lua")

            local parsed = loop._parse_args(args)

            assert.equals(parsed[2],
                          test_utils.test_dir .. "/files/test-file.lua")
        end)

        it("should replace $TEXT with buffer content", function()
            local args = {"--stdin", "text=$TEXT"}
            test_utils.edit_test_file("test-file.lua")

            local parsed = loop._parse_args(args)

            assert.equals(parsed[2], "text=print(\"I am a test file!\")\n")
        end)

        it("should return unmodified argument", function()
            local args = {"--mock-flag", "mock-value"}
            test_utils.edit_test_file("test-file.lua")

            local parsed = loop._parse_args(args)

            assert.same(parsed, args)
        end)
    end)

    describe("spawn", function()
        stub(vim, "schedule_wrap")
        local mock_cmd = "cat"
        local mock_args = {"-n"}
        local mock_handler = stub.new()
        local check_exit_code = stub.new()

        local mock_handle = {}
        local mock_handle_is_closing = stub.new()
        local mock_handle_close = stub.new()
        local mock_stdin = {}
        local mock_stdin_write = stub.new()
        local mock_stdin_close = stub.new()
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
                handler = function(...) mock_handler(...) end,
                check_exit_code = check_exit_code
            }

            function mock_stdin:write(...) mock_stdin_write(...) end
            function mock_stdin:close() mock_stdin_close() end
            function mock_handle:is_closing()
                return mock_handle_is_closing()
            end
            function mock_handle:close() mock_handle_close() end
            function mock_stdout:read_stop() mock_stdout_read_stop() end
            function mock_stdout:is_closing()
                return mock_stdout_is_closing()
            end
            function mock_stdout:close() mock_stdout_close() end
            function mock_stderr:read_stop() mock_stderr_read_stop() end
            function mock_stderr:is_closing()
                return mock_stderr_is_closing()
            end
            function mock_stderr:close() mock_stderr_close() end
        end)

        after_each(function()
            mock_handler:clear()
            mock_stdin_write:clear()
            mock_stdin_close:clear()
            mock_handle_is_closing:clear()
            mock_handle_close:clear()
            mock_stdout_read_stop:clear()
            mock_stdout_is_closing:clear()
            mock_stdout_close:clear()
            mock_stderr_read_stop:clear()
            mock_stderr_is_closing:clear()
            mock_stderr_close:clear()

            vim.schedule_wrap:clear()
            uv.spawn:clear()
            uv.read_start:clear()
            uv.new_pipe:clear()
        end)

        it("should call uv.spawn with cmd and args", function()
            loop.spawn(mock_cmd, mock_args, mock_opts)

            assert.stub(uv.spawn).was_called()
            assert.equals(uv.spawn.calls[1].refs[1], mock_cmd)
            assert.same(uv.spawn.calls[1].refs[2].args, mock_args)
        end)

        it("should call uv.read_start twice", function()
            loop.spawn(mock_cmd, mock_args, mock_opts)

            assert.stub(uv.read_start).was_called(2)
        end)

        describe("stdin", function()
            it("should call stdin:write when input is given", function()
                uv.new_pipe.returns(mock_stdin)
                local mock_input = "I have content"
                mock_opts.input = mock_input

                loop.spawn(mock_cmd, mock_args, mock_opts)

                assert.stub(mock_stdin_write).was_called()
                assert.equals(mock_stdin_write.calls[1].refs[1], mock_input)
            end)

            it("should call stdin:close in callback", function()
                uv.new_pipe.returns(mock_stdin)
                local mock_input = "I have content"
                mock_opts.input = mock_input
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local callback = mock_stdin_write.calls[1].refs[2]
                callback()

                assert.stub(mock_stdin_close).was_called()
            end)
        end)

        describe("handle_stdout", function()
            local handle_stdout
            before_each(function()
                loop.spawn(mock_cmd, mock_args, mock_opts)
                handle_stdout = vim.schedule_wrap.calls[1].refs[1]
            end)

            it("should throw error if err is passed in", function()
                assert.has_error(function()
                    handle_stdout("error", nil)
                end)
            end)

            it(
                "should append chunks to output and call handler when output is nil",
                function()
                    handle_stdout(nil, "chunk1")
                    handle_stdout(nil, "chunk2")
                    handle_stdout(nil, nil)

                    local output = mock_handler.calls[1].refs[2]

                    assert.equals(output, "chunk1chunk2")
                end)

            it("should set output to nil if empty string", function()
                handle_stdout(nil, "")
                handle_stdout(nil, nil)

                local output = mock_handler.calls[1].refs[2]

                assert.equals(output, nil)
            end)

            it("should set error_output to nil if empty string", function()
                handle_stdout(nil, "")
                handle_stdout(nil, nil)

                local error_output = mock_handler.calls[1].refs[1]

                assert.equals(error_output, nil)
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

        describe("exit code", function()
            stub(vim, "wait")

            before_each(function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
            end)
            after_each(function()
                vim.wait:clear()
                check_exit_code:clear()
            end)

            it("should check that code is 0 when check_exit_code is nil",
               function()
                mock_opts.check_exit_code = nil
                loop.spawn(mock_cmd, mock_args, mock_opts)
                local callback = vim.schedule_wrap.calls[2].refs[1]
                local handle_stdout = vim.schedule_wrap.calls[1].refs[1]

                callback(0)
                handle_stdout(nil, nil)
                local done = vim.wait.calls[1].refs[2]

                assert.stub(check_exit_code).was_not_called()
                assert.equals(done(), true)
            end)

            it("should check exit code with check_exit_code callback",
               function()
                check_exit_code.returns(false)
                loop.spawn(mock_cmd, mock_args, mock_opts)
                local callback = vim.schedule_wrap.calls[2].refs[1]
                local handle_stdout = vim.schedule_wrap.calls[1].refs[1]

                callback(255)
                handle_stdout(nil, nil)
                local done = vim.wait.calls[1].refs[2]

                assert.stub(check_exit_code).was_called_with(255)
                assert.equals(done(), true)
            end)

            it("should swap output and error_output if exit_ok is false",
               function()
                check_exit_code.returns(false)
                loop.spawn(mock_cmd, mock_args, mock_opts)
                local callback = vim.schedule_wrap.calls[2].refs[1]
                local handle_stdout = vim.schedule_wrap.calls[1].refs[1]

                callback(255)
                handle_stdout(nil, "bad")
                handle_stdout(nil, nil)

                assert.stub(mock_handler).was_called_with("bad", nil)
            end)
        end)

        describe("spawn callback", function()
            it("should call close_handle on spawn handle", function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local callback = vim.schedule_wrap.calls[2].refs[1]
                callback()

                assert.stub(mock_handle_is_closing).was_called()
                assert.stub(mock_handle_close).was_called()
            end)

            it("should not call close_handle if is_closing returns true",
               function()
                uv.new_pipe.returns(mock_stdout)
                uv.spawn.returns(mock_handle)
                mock_handle_is_closing.returns(true)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local callback = vim.schedule_wrap.calls[2].refs[1]
                callback()

                assert.stub(mock_handle_is_closing).was_called()
                assert.stub(mock_handle_close).was_not_called()
            end)

            it("should call read_stop and close_handle on stdout handle",
               function()
                uv.new_pipe.returns(mock_stdout)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local callback = vim.schedule_wrap.calls[2].refs[1]
                callback()

                assert.stub(mock_stdout_read_stop).was_called()
                assert.stub(mock_stdout_is_closing).was_called()
                assert.stub(mock_stdout_close).was_called()
            end)

            it("should call read_stop and close_handle on stderr handle",
               function()
                uv.new_pipe.returns(mock_stderr)
                loop.spawn(mock_cmd, mock_args, mock_opts)

                local callback = vim.schedule_wrap.calls[2].refs[1]
                callback()

                assert.stub(mock_stderr_read_stop).was_called()
                assert.stub(mock_stderr_is_closing).was_called()
                assert.stub(mock_stderr_close).was_called()
            end)
        end)
    end)

    describe("timer", function()
        stub(vim, "schedule_wrap")
        local mock_timer = {}
        local start = stub.new()
        local stop = stub.new()
        function mock_timer:start(...) start(...) end
        function mock_timer:stop() stop() end

        local timeout = 10
        local interval = 5
        local callback_spy = stub.new()
        local callback = function() callback_spy() end

        before_each(function()
            uv.new_timer.returns(mock_timer)
            vim.schedule_wrap.returns("wrapped")
        end)
        after_each(function()
            vim.schedule_wrap:clear()
            callback_spy:clear()
            start:clear()
            stop:clear()
        end)

        it("should return object with methods and original timer", function()
            local timer = loop.timer(timeout, interval, false, callback)

            assert.truthy(timer.start)
            assert.truthy(timer.stop)
            assert.truthy(timer.restart)
            assert.equals(timer._timer, mock_timer)
        end)

        it("should pass callback to schedule_wrap", function()
            loop.timer(timeout, interval, false, callback)

            vim.schedule_wrap.calls[1].refs[1]()

            assert.stub(callback_spy).was_called()
        end)

        it("should call uv timer start method on start", function()
            local timer = loop.timer(timeout, interval, false, callback)

            timer.start()

            assert.stub(start).was_called_with(timeout, interval, "wrapped")
        end)

        it("should default interval to 0 when nil", function()
            local timer = loop.timer(timeout, nil, false, callback)

            timer.start()

            assert.stub(start).was_called_with(timeout, 0, "wrapped")
        end)

        it("should start timer when should_start = true", function()
            loop.timer(timeout, nil, true, callback)

            assert.stub(start).was_called_with(timeout, 0, "wrapped")
        end)

        describe("restart", function()
            it(
                "should restart timer with original interval and wrapped callback",
                function()
                    local timer = loop.timer(timeout, interval, false, callback)

                    timer.restart()

                    assert.stub(stop).was_called()
                    assert.stub(start).was_called_with(timeout, interval,
                                                       "wrapped")
                end)

            it("should restart timer with new timeout and interval", function()
                local timer = loop.timer(timeout, interval, false, callback)
                local new_timeout = 100
                local new_interval = 99

                timer.restart(new_timeout, new_interval)

                assert.stub(stop).was_called()
                assert.stub(start).was_called_with(new_timeout, new_interval,
                                                   "wrapped")
            end)
        end)
    end)
end)
