local mock = require("luassert.mock")
local stub = require("luassert.stub")

local c = require("null-ls.config")
local helpers = require("null-ls.helpers")
local loop = require("null-ls.loop")
local s = require("null-ls.state")

mock(require("null-ls.logger"), true)

local test_utils = require("null-ls.utils.test")
local root = vim.fn.getcwd()

describe("generator_factory", function()
    stub(loop, "spawn")
    stub(loop, "temp_file")
    stub(loop, "read_file")
    stub(s, "get_cache")
    stub(s, "set_cache")

    local validate = stub(vim, "validate")
    local done = stub.new()
    local on_output = stub.new()

    local command = "cat"
    local args = { "-n" }

    c.setup({ log_level = "off" })

    local generator_opts
    before_each(function()
        generator_opts = {
            command = command,
            args = args,
            on_output = function(...)
                on_output(...)
            end,
        }
    end)

    after_each(function()
        done:clear()
        on_output:clear()

        loop.spawn:clear()
        loop.temp_file:clear()
        loop.read_file:clear()

        s.get_cache:clear()
        s.set_cache:clear()

        validate:clear()
        vim.validate = validate

        c.reset()
    end)

    describe("parse_args", function()
        it("should replace $FILENAME with buffer name", function()
            generator_opts.args = { "--stdin-filename", "$FILENAME" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ bufname = "/files/test-file.lua" }, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[2], "/files/test-file.lua")
        end)

        it("should replace $FILENAME with temp file path", function()
            generator_opts.args = { "--stdin-filename", "$FILENAME" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ temp_path = "/tmp/temp-file.lua" }, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[2], "/tmp/temp-file.lua")
        end)

        it("should replace $DIRNAME with buffer's directory name", function()
            generator_opts.args = { "--stdin-filename", "$DIRNAME" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ bufname = "/files/test-file.lua" }, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[2], "/files")
        end)

        it("should replace $TEXT with buffer content", function()
            generator_opts.args = { "--stdin", "text=$TEXT" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ content = { "content" } }, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[2], "text=content")
        end)

        it("should replace $FILEEXT with file extension", function()
            generator_opts.args = { "$FILEEXT" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ bufname = "/files/test-file.lua" }, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[1], "lua")
        end)

        it("should replace $ROOT with root", function()
            generator_opts.args = { "$ROOT" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[1], root)
        end)

        it("should not modify non-matching variable", function()
            generator_opts.args = { "echo $0" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.equals(parsed[1], "echo $0")
        end)

        it("should return unmodified arguments", function()
            generator_opts.args = { "--mock-flag", "mock-value" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local parsed = loop.spawn.calls[1].refs[2]
            assert.same(parsed, generator_opts.args)
        end)
    end)

    describe("parse_env", function()
        it("should pass in the environment variables to the command", function()
            generator_opts.env = { TEST = "TESTING" }

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local parsed = loop.spawn.calls[1].refs[3]
            assert.same(parsed.env, generator_opts.env)
        end)

        it("should resolve function as a table of environment variables", function()
            local environment_variables = { TEST = "TESTING" }

            generator_opts.env = function()
                return environment_variables
            end

            local generator = helpers.generator_factory(generator_opts)
            local params = {}
            generator.fn(params, done)

            local parsed = loop.spawn.calls[1].refs[3]
            assert.same(parsed.env, environment_variables)
            assert.same(params.command, command)
        end)
    end)

    describe("json_output_wrapper", function()
        describe("format == json", function()
            local generator
            before_each(function()
                generator_opts.format = "json"
                generator = helpers.generator_factory(generator_opts)
            end)

            it("should return error if json decode fails", function()
                local bad_json = "this is not json"

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, bad_json)

                local generator_err = done.calls[1].refs[1]._generator_err
                assert.truthy(generator_err:find("failed to decode json"))
            end)

            it("should set output to decoded json", function()
                local good_json = vim.json.encode({ key = "val" })

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, good_json)

                local output = on_output.calls[1].refs[1].output
                assert.same(output, { key = "val" })
            end)

            it("should return without calling on_output if output is nil", function()
                local good_json = vim.json.encode(nil)

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, good_json)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)

            it("should return without calling on_output if output is empty string", function()
                local good_json = vim.json.encode("")

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, good_json)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)

            it("should return without calling on_output if output is empty table", function()
                local good_json = vim.json.encode({})

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, good_json)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)
        end)

        describe("format == json_raw", function()
            local generator
            before_each(function()
                generator_opts.format = "json_raw"
                generator = helpers.generator_factory(generator_opts)
            end)

            it("should set params.err if json decode fails", function()
                local bad_json = "this is not json"

                generator.fn({}, done)
                local handler = loop.spawn.calls[1].refs[3].handler
                handler(nil, bad_json)

                assert.truthy(on_output.calls[1].refs[1].err)
                assert.truthy(on_output.calls[1].refs[1].err:match("failed to decode json"))
            end)
        end)
    end)

    describe("line_output_wrapper", function()
        local generator
        before_each(function()
            generator_opts.format = "line"
            generator = helpers.generator_factory(generator_opts)
        end)

        it("should call done and return if output is nil", function()
            generator.fn({}, done)
            local handler = loop.spawn.calls[1].refs[3].handler

            handler(nil, nil)

            assert.stub(done).was_called()
            assert.stub(on_output).was_not_called()
        end)

        it("should call done and return if output is empty string", function()
            generator.fn({}, done)
            local handler = loop.spawn.calls[1].refs[3].handler

            handler(nil, "")

            assert.stub(done).was_called()
            assert.stub(on_output).was_not_called()
        end)

        it("should call on_output once for each line", function()
            generator.fn({}, done)
            local handler = loop.spawn.calls[1].refs[3].handler

            handler(nil, "line1\nline2\nline3")

            assert.stub(on_output).was_called(3)
            assert.equals(on_output.calls[1].refs[1], "line1")
            assert.equals(on_output.calls[2].refs[1], "line2")
            assert.equals(on_output.calls[3].refs[1], "line3")
        end)

        it("should normalize line endings", function()
            generator.fn({}, done)
            local handler = loop.spawn.calls[1].refs[3].handler

            handler(nil, "line1\r\nline2\r\nline3")

            assert.stub(on_output).was_called(3)
            assert.equals(on_output.calls[1].refs[1], "line1")
            assert.equals(on_output.calls[2].refs[1], "line2")
            assert.equals(on_output.calls[3].refs[1], "line3")
        end)

        it("should handle mixed line endings", function()
            generator.fn({}, done)
            local handler = loop.spawn.calls[1].refs[3].handler

            handler(nil, "line1\r\nline2\nline3")

            assert.stub(on_output).was_called(3)
            assert.equals(on_output.calls[1].refs[1], "line1")
            assert.equals(on_output.calls[2].refs[1], "line2")
            assert.equals(on_output.calls[3].refs[1], "line3")
        end)
    end)

    describe("validate", function()
        it("should validate opts on first run", function()
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.stub(validate).was_called()
        end)

        it("should trigger deregistration if validation fails", function()
            vim.validate = function(_)
                error("validation failed")
            end

            local generator = helpers.generator_factory(generator_opts)

            generator.fn({}, done)

            assert.stub(done).was_called_with({ _should_deregister = true })
        end)

        it("should not validate opts on subsequent runs", function()
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})
            generator.fn({})

            assert.stub(validate).was_called(1)
        end)
    end)

    describe("command", function()
        it("should call command function with params ", function()
            local params
            generator_opts.command = function(_params)
                params = _params
                return "cat"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({ test_key = "test_val" })

            assert.truthy(params)
            assert.equals(params.test_key, "test_val")
        end)

        it("should set command from function return value", function()
            generator_opts.command = function()
                return "cat"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({})

            assert.stub(loop.spawn).was_called()
            assert.equals(loop.spawn.calls[1].refs[1], "cat")
            assert.equals(generator_opts.command, "cat")
        end)

        it("should only set command once", function()
            local count = 0
            generator_opts.command = function()
                count = count + 1
                return "cat"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({})
            generator.fn({})

            assert.equals(count, 1)
        end)

        it("should call dynamic_command with params but not override original command", function()
            local original_command
            generator_opts.dynamic_command = function(params)
                original_command = params.command
                return "tldr"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({})

            assert.equals(loop.spawn.calls[1].refs[1], "tldr")
            assert.equals(generator_opts.command, original_command)
            assert.equals(generator_opts.command, "cat")
        end)

        it("should not spawn command and return done if dynamic_command returns nil", function()
            generator_opts.dynamic_command = function()
                return nil
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            assert.stub(loop.spawn).was_not_called()
            assert.stub(done).was_called()
        end)

        it("should call dynamic_command once on each run", function()
            local count = 0
            generator_opts.dynamic_command = function()
                count = count + 1
                return "cat"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({})
            generator.fn({})

            assert.equals(count, 2)
        end)

        it("should set generator.opts.command to function return value", function()
            generator_opts.command = function()
                return "cat"
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({})

            assert.equals(generator.opts.command, "cat")
        end)
    end)

    it("should set _last_args, _last_command, and _last_cwd from last resolved", function()
        generator_opts.command = function()
            return "cat"
        end
        generator_opts.args = function()
            return { "-b" }
        end

        local generator = helpers.generator_factory(generator_opts)
        generator.fn({})

        assert.equals(generator.opts._last_command, "cat")
        assert.same(generator.opts._last_args, { "-b" })
        assert.same(generator.opts._last_cwd, vim.loop.cwd())
    end)

    it("should set async to true", function()
        local generator = helpers.generator_factory(generator_opts)

        assert.equals(generator.async, true)
    end)

    it("should pass filetypes to generator", function()
        generator_opts.filetypes = { "lua" }

        local generator = helpers.generator_factory(generator_opts)

        assert.same(generator.filetypes, { "lua" })
    end)

    it("should pass multiple_files to generator", function()
        generator_opts.multiple_files = true

        local generator = helpers.generator_factory(generator_opts)

        assert.truthy(generator.multiple_files)
    end)

    it("should pass prepend_extra_args to generator", function()
        generator_opts.prepend_extra_args = true

        local generator = helpers.generator_factory(generator_opts)

        assert.truthy(generator.prepend_extra_args)
    end)

    it("should wrap check_exit_code if it's a table", function()
        generator_opts.check_exit_code = { 0 }
        local generator = helpers.generator_factory(generator_opts)

        generator.fn({})

        local spawn_opts = loop.spawn.calls[1].refs[3]
        assert.equals(type(spawn_opts.check_exit_code), "function")
        assert.equals(spawn_opts.check_exit_code(0), true)
        assert.equals(spawn_opts.check_exit_code(1), false)
    end)

    describe("fn", function()
        it("should call loop.spawn with command and args", function()
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.stub(loop.spawn).was_called()
            assert.equals(loop.spawn.calls[1].refs[1], command)
            assert.same(loop.spawn.calls[1].refs[2], args)
        end)

        it("should call loop.spawn with default args (empty table)", function()
            generator_opts.args = nil
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.same(loop.spawn.calls[1].refs[2], {})
        end)

        it("should call loop.spawn with specified timeout", function()
            generator_opts.timeout = 500
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.same(loop.spawn.calls[1].refs[3].timeout, 500)
        end)

        it("should call loop.spawn with default timeout", function()
            generator_opts.timeout = nil
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.same(loop.spawn.calls[1].refs[3].timeout, c.get().default_timeout)
        end)

        it("should call loop.spawn with the result of the specified cwd function", function()
            generator_opts.cwd = function(params)
                assert.same(params.root, root)
                return "foo"
            end
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.same(loop.spawn.calls[1].refs[3].cwd, "foo")
        end)

        it("should call loop.spawn with default root as cwd if no cwd given", function()
            generator_opts.cwd = nil
            local generator = helpers.generator_factory(generator_opts)

            generator.fn({})

            assert.same(loop.spawn.calls[1].refs[3].cwd, root)
        end)

        it("should call loop.spawn with buffer content as string when to_stdin = true", function()
            test_utils.edit_test_file("test-file.lua")
            local params = { bufnr = vim.api.nvim_get_current_buf() }
            generator_opts.to_stdin = true

            local generator = helpers.generator_factory(generator_opts)
            generator.fn(params)

            local input = loop.spawn.calls[1].refs[3].input
            assert.equals(input, 'print("I am a test file!")\n')
        end)

        describe("to_temp_file", function()
            local cleanup = stub.new()
            loop.temp_file.returns("temp-path", cleanup)

            local params, temp_file_generator_opts
            before_each(function()
                params = { content = { "buffer content" }, bufname = "mock-file.lua" }

                temp_file_generator_opts = vim.deepcopy(generator_opts)
                temp_file_generator_opts.to_temp_file = true
                temp_file_generator_opts.args = { "$FILENAME" }
            end)

            after_each(function()
                cleanup:clear()
            end)

            it("should call loop.temp_file with content, bufname, and nil dirname", function()
                local generator = helpers.generator_factory(temp_file_generator_opts)

                generator.fn(params)

                assert.stub(loop.temp_file).was_called_with("buffer content", params.bufname, nil)
            end)

            it("should call loop.temp_file with source-specific temp_dir", function()
                temp_file_generator_opts.temp_dir = "/source-temp-dir"
                local generator = helpers.generator_factory(temp_file_generator_opts)

                generator.fn(params)

                assert
                    .stub(loop.temp_file)
                    .was_called_with("buffer content", params.bufname, temp_file_generator_opts.temp_dir)
            end)

            it("should call loop.temp_file with global temp_dir", function()
                c._set({ temp_dir = "/global-temp-dir" })
                local generator = helpers.generator_factory(temp_file_generator_opts)

                generator.fn(params)

                assert.stub(loop.temp_file).was_called_with("buffer content", params.bufname, c.get().temp_dir)
            end)

            it("should replace $FILENAME arg with temp path", function()
                local generator = helpers.generator_factory(temp_file_generator_opts)

                generator.fn(params)

                assert.same(loop.spawn.calls[1].refs[2], { "temp-path" })
            end)

            it("should assign temp_path to params", function()
                local generator = helpers.generator_factory(temp_file_generator_opts)

                generator.fn(params)

                assert.equals(params.temp_path, "temp-path")
            end)

            it("should call cleanup callback in on_stdout_end", function()
                local generator = helpers.generator_factory(temp_file_generator_opts)
                generator.fn(params)

                local on_stdout_end = loop.spawn.calls[1].refs[3].on_stdout_end
                on_stdout_end()

                assert.stub(cleanup).was_called()
            end)
        end)

        describe("from_temp_file", function()
            local cleanup = stub.new()

            local params
            local on_stdout_end
            before_each(function()
                loop.temp_file.returns("temp-path", cleanup)

                generator_opts.to_temp_file = true
                generator_opts.from_temp_file = true

                local generator = helpers.generator_factory(generator_opts)
                params = {}
                generator.fn(params)
                on_stdout_end = loop.spawn.calls[1].refs[3].on_stdout_end
            end)
            after_each(function()
                cleanup:clear()
            end)

            it("should call loop.read_file with temp path", function()
                on_stdout_end()

                assert.stub(loop.read_file).was_called_with("temp-path")
            end)

            it("should set params.output to temp file content", function()
                loop.read_file.returns("content")

                on_stdout_end()

                assert.equals(params.output, "content")
            end)
        end)

        describe("use_cache", function()
            it("should call wrapper with cached output and return", function()
                s.get_cache.returns("cached")
                generator_opts.use_cache = true

                helpers.generator_factory(generator_opts).fn({})

                assert.stub(loop.spawn).was_not_called()
                assert.equals(on_output.calls[1].refs[1].output, "cached")
                assert.equals(on_output.calls[1].refs[1]._null_ls_cached, true)
            end)

            it("should pass cached output as output when from_stderr is true", function()
                s.get_cache.returns("cached")
                generator_opts.use_cache = true
                generator_opts.from_stderr = true

                helpers.generator_factory(generator_opts).fn({})

                assert.equals(on_output.calls[1].refs[1].output, "cached")
                assert.equals(on_output.calls[1].refs[1]._null_ls_cached, true)
            end)

            it("should call spawn when cache is empty", function()
                s.get_cache.returns(nil)
                generator_opts.use_cache = true

                local generator = helpers.generator_factory(generator_opts)
                generator.fn({})

                assert.stub(loop.spawn).was_called()
            end)
        end)
    end)

    describe("wrapper", function()
        it("should set params.output and call on_output with params", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            assert.equals(on_output.calls[1].refs[1].output, "output")
        end)

        it("should set opts._last_output to output", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            assert.equals(generator_opts._last_output, "output")
        end)

        it("should set opts._last_output to empty string if output is nil", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, nil)

            assert.equals(generator_opts._last_output, "")
        end)

        it("should call done when on_output is called", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)
            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            local wrapped_done = on_output.calls[1].refs[2]
            wrapped_done()

            assert.stub(done).was_called()
        end)

        it("should call done only once when wrapper is called multiple times", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)
            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            local wrapped_done = on_output.calls[1].refs[2]
            wrapped_done()
            wrapped_done()

            assert.stub(done).was_called(1)
        end)

        it("should set output to error_output and error_output to nil if from_stderr = true", function()
            generator_opts.from_stderr = true
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper("error output", nil)

            assert.equals(on_output.calls[1].refs[1].output, "error output")
        end)

        it("should ignore error output if ignore_stderr = true", function()
            generator_opts.ignore_stderr = true
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper("error output", "normal output")

            assert.equals(on_output.calls[1].refs[1].output, "normal output")
        end)

        it("should not override params.output if already set", function()
            local params = { output = "original output" }
            local generator = helpers.generator_factory(generator_opts)
            generator.fn(params, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "new output")

            assert.equals(on_output.calls[1].refs[1].output, "original output")
        end)

        it("should catch error thrown in handle_output", function()
            generator_opts.on_output = function()
                error("handle_output error")
            end

            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            local generator_err = done.calls[1].refs[1]._generator_err
            assert.truthy(generator_err)
            assert.truthy(generator_err:find("handle_output error"))
        end)

        it("should pass error to done if error_output exists and format ~= raw", function()
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper("error output", nil)

            local generator_err = done.calls[1].refs[1]._generator_err
            assert.truthy(generator_err)
            assert.truthy(generator_err:find("error output"))
        end)

        it("should set params.err if format == raw", function()
            generator_opts.format = "raw"
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper("error output", nil)

            assert.equals(on_output.calls[1].refs[1].err, "error output")
        end)

        it("should set params.err if format == json_raw", function()
            generator_opts.format = "json_raw"
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper("error output", nil)

            assert.equals(on_output.calls[1].refs[1].err, "error output")
        end)

        it("should call json_output_wrapper and return if format == json", function()
            generator_opts.format = "json"
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, vim.fn.json_encode({ key = "val" }))

            assert.same(on_output.calls[1].refs[1].output, { key = "val" })
        end)

        it("should call json_output_wrapper and return if format == json_raw", function()
            generator_opts.format = "json_raw"
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, vim.fn.json_encode({ key = "val" }))

            assert.same(on_output.calls[1].refs[1].output, { key = "val" })
        end)

        it("should call line_output_wrapper and return if format == line", function()
            generator_opts.format = "line"
            local generator = helpers.generator_factory(generator_opts)
            generator.fn({}, done)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            assert.equals(on_output.calls[1].refs[1], "output")
            assert.equals(on_output.calls[1].refs[2].output, "output")
        end)

        it("should call set_cache with bufnr, command, and output if use_cache is true", function()
            local params = { bufnr = 1 }
            generator_opts.use_cache = true
            helpers.generator_factory(generator_opts).fn(params)

            local wrapper = loop.spawn.calls[1].refs[3].handler
            wrapper(nil, "output")

            assert.stub(s.set_cache).was_called_with(params.bufnr, generator_opts.command, "output")
        end)
    end)
end)
