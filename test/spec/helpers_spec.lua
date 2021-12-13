local stub = require("luassert.stub")
local loop = require("null-ls.loop")

local c = require("null-ls.config")
local s = require("null-ls.state")
local test_utils = require("test.utils")

describe("helpers", function()
    _G._TEST = true
    local root = vim.fn.getcwd()

    stub(vim, "validate")

    local done = stub.new()
    local on_output = stub.new()

    after_each(function()
        done:clear()
        on_output:clear()
        vim.validate:clear()
    end)

    local helpers = require("null-ls.helpers")

    describe("parse_args", function()
        it("should replace $FILENAME with buffer name", function()
            local args = { "--stdin-filename", "$FILENAME" }

            local parsed = helpers._parse_args(args, { bufname = "/files/test-file.lua" })

            assert.equals(parsed[2], "/files/test-file.lua")
        end)

        it("should replace $FILENAME with temp file path", function()
            local args = { "--stdin-filename", "$FILENAME" }

            local parsed = helpers._parse_args(args, { temp_path = "/tmp/temp-file.lua" })

            assert.equals(parsed[2], "/tmp/temp-file.lua")
        end)

        it("should replace $DIRNAME with buffer's directory name", function()
            local args = { "--stdin-filename", "$DIRNAME" }

            local parsed = helpers._parse_args(args, { bufname = "/files/test-file.lua" })

            assert.equals(parsed[2], "/files")
        end)

        it("should replace $TEXT with buffer content", function()
            local args = { "--stdin", "text=$TEXT" }

            local parsed = helpers._parse_args(args, { content = { "content" } })

            assert.equals(parsed[2], "text=content")
        end)

        it("should replace $FILEEXT with file extension", function()
            local args = { "$FILEEXT" }

            local parsed = helpers._parse_args(args, { bufname = "/files/test-file.lua" })

            assert.equals(parsed[1], "lua")
        end)

        it("should replace $ROOT with root", function()
            local args = { "$ROOT" }

            local parsed = helpers._parse_args(args, { root = "root" })

            assert.equals(parsed[1], "root")
        end)

        it("should not modify non-matching variable", function()
            local args = { "echo $0" }

            local parsed = helpers._parse_args(args, {})

            assert.equals(parsed[1], "echo $0")
        end)

        it("should return unmodified argument", function()
            local args = { "--mock-flag", "mock-value" }

            local parsed = helpers._parse_args(args, {})

            assert.same(parsed, args)
        end)
    end)

    describe("json_output_wrapper", function()
        describe("format == json", function()
            local format = "json"

            it("should throw error if json decode fails", function()
                local bad_json = "this is not json"

                assert.has_error(function()
                    helpers._json_output_wrapper({ output = bad_json }, done, on_output, format)
                end)
            end)

            it("should set output to decoded json", function()
                local good_json = vim.fn.json_encode({ key = "val" })

                helpers._json_output_wrapper({ output = good_json }, done, on_output, format)

                local output = on_output.calls[1].refs[1].output
                assert.same(output, { key = "val" })
            end)

            it("should return without calling on_output if output is nil", function()
                local good_json = vim.fn.json_encode(nil)

                helpers._json_output_wrapper({ output = good_json }, done, on_output, format)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)

            it("should return without calling on_output if output is empty string", function()
                local good_json = vim.fn.json_encode("")

                helpers._json_output_wrapper({ output = good_json }, done, on_output, format)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)

            it("should return without calling on_output if output is empty table", function()
                local good_json = vim.fn.json_encode({})

                helpers._json_output_wrapper({ output = good_json }, done, on_output, format)

                assert.stub(done).was_called()
                assert.stub(on_output).was_not_called()
            end)

            it("should call done and on_output with updated params", function()
                local good_json = vim.fn.json_encode({ key = "val" })

                helpers._json_output_wrapper({ output = good_json }, done, on_output, format)

                assert.stub(done).was_called()
                assert.stub(on_output).was_called_with({ output = { key = "val" } })
            end)
        end)

        describe("format == json_raw", function()
            local format = "json_raw"

            it("should set params.err if json decode fails", function()
                local bad_json = "this is not json"

                helpers._json_output_wrapper({ output = bad_json }, done, on_output, format)

                assert.truthy(on_output.calls[1].refs[1].err)
            end)
        end)
    end)

    describe("line_output_wrapper", function()
        it("should call done and return if output is nil", function()
            helpers._line_output_wrapper({ output = nil }, done, on_output)

            assert.stub(done).was_called()
            assert.stub(on_output).was_not_called()
        end)

        it("should call done and return if output is empty string", function()
            helpers._line_output_wrapper({ output = "" }, done, on_output)

            assert.stub(done).was_called()
            assert.stub(on_output).was_not_called()
        end)

        it("should call on_output once for each line", function()
            helpers._line_output_wrapper({ output = "line1\nline2\nline3" }, done, on_output)

            assert.stub(on_output).was_called(3)
            assert.equals(on_output.calls[1].refs[1], "line1")
            assert.equals(on_output.calls[2].refs[1], "line2")
            assert.equals(on_output.calls[3].refs[1], "line3")
        end)

        it("should call done with all_results", function()
            on_output.returns({ "results" })

            helpers._line_output_wrapper({ output = "line1\nline2\nline3" }, done, on_output)

            assert.same(done.calls[1].refs[1], { { "results" }, { "results" }, { "results" } })
        end)
    end)

    describe("generator_factory", function()
        stub(loop, "spawn")
        stub(loop, "temp_file")
        stub(s, "get_cache")
        stub(s, "set_cache")

        local command = "cat"
        local args = { "-n" }
        local generator_args
        before_each(function()
            generator_args = {
                command = command,
                args = args,
                on_output = function(...)
                    on_output(...)
                end,
            }
        end)

        after_each(function()
            loop.spawn:clear()
            loop.temp_file:clear()
            s.get_cache:clear()
            s.set_cache:clear()
        end)

        it("should validate opts on first run", function()
            local generator = helpers.generator_factory(generator_args)

            generator.fn({})

            assert.stub(vim.validate).was_called()
        end)

        it("should not validate opts on subsequent runs", function()
            local generator = helpers.generator_factory(generator_args)

            generator.fn({})
            generator.fn({})

            assert.stub(vim.validate).was_called(1)
        end)

        it("should throw error if command is not executable", function()
            generator_args.command = "nonexistent"

            local generator = helpers.generator_factory(generator_args)
            local _, err = pcall(generator.fn, {})

            assert.truthy(err)
            assert.truthy(err:match("command nonexistent is not executable"))
        end)

        it("should not validate command if dynamic_command is set", function()
            generator_args.command = "nonexistent"
            generator_args.dynamic_command = function()
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            local _, err = pcall(generator.fn, {})

            assert.falsy(err)
        end)

        it("should call command function with params ", function()
            local params
            generator_args.command = function(_params)
                params = _params
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({ test_key = "test_val" })

            assert.truthy(params)
            assert.equals(params.test_key, "test_val")
        end)

        it("should set command from function return value", function()
            generator_args.command = function()
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})

            assert.stub(loop.spawn).was_called()
            assert.equals(loop.spawn.calls[1].refs[1], "cat")
            assert.equals(generator_args.command, "cat")
        end)

        it("should only set command once", function()
            local count = 0
            generator_args.command = function()
                count = count + 1
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})
            generator.fn({})

            assert.equals(count, 1)
        end)

        it("should call dynamic_command with params but not override original command", function()
            local original_command
            generator_args.dynamic_command = function(params)
                original_command = params.command
                return "tldr"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})

            assert.equals(loop.spawn.calls[1].refs[1], "tldr")
            assert.equals(generator_args.command, original_command)
            assert.equals(generator_args.command, "cat")
        end)

        it("should not spawn command and return done if dynamic_command returns nil", function()
            generator_args.dynamic_command = function()
                return nil
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({}, done)

            assert.stub(loop.spawn).was_not_called()
            assert.stub(done).was_called()
        end)

        it("should call dynamic_command once on each run", function()
            local count = 0
            generator_args.dynamic_command = function()
                count = count + 1
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})
            generator.fn({})

            assert.equals(count, 2)
        end)

        it("should set generator.opts.command to function return value", function()
            generator_args.command = function()
                return "cat"
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})

            assert.equals(generator.opts.command, "cat")
        end)

        it("should set _last_args, _last_command, and _last_cwd from last resolved", function()
            generator_args.command = function()
                return "cat"
            end
            generator_args.args = function()
                return { "-b" }
            end

            local generator = helpers.generator_factory(generator_args)
            generator.fn({})

            assert.equals(generator.opts._last_command, "cat")
            assert.same(generator.opts._last_args, { "-b" })
            assert.same(generator.opts._last_cwd, vim.loop.cwd())
        end)

        it("should throw error if from_temp_file = true but to_temp_file is not", function()
            generator_args.from_temp_file = true
            local generator = helpers.generator_factory(generator_args)

            local _, err = pcall(generator.fn, {})

            assert.truthy(err)
            assert.truthy(err:match("from_temp_file requires to_temp_file"))
        end)

        it("should set async to true", function()
            local generator = helpers.generator_factory(generator_args)

            assert.equals(generator.async, true)
        end)

        it("should pass filetypes to generator", function()
            generator_args.filetypes = { "lua" }

            local generator = helpers.generator_factory(generator_args)

            assert.same(generator.filetypes, { "lua" })
        end)

        it("should pass multiple_files to generator", function()
            generator_args.multiple_files = true

            local generator = helpers.generator_factory(generator_args)

            assert.truthy(generator.multiple_files)
        end)

        it("should wrap check_exit_code if it's a table", function()
            generator_args.check_exit_code = { 0 }
            local generator = helpers.generator_factory(generator_args)

            generator.fn({})

            local spawn_opts = loop.spawn.calls[1].refs[3]
            assert.equals(type(spawn_opts.check_exit_code), "function")
            assert.equals(spawn_opts.check_exit_code(0), true)
            assert.equals(spawn_opts.check_exit_code(1), false)
        end)

        describe("fn", function()
            it("should call loop.spawn with command and args", function()
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.stub(loop.spawn).was_called()
                assert.equals(loop.spawn.calls[1].refs[1], command)
                assert.same(loop.spawn.calls[1].refs[2], args)
            end)

            it("should call loop.spawn with default args (empty table)", function()
                generator_args.args = nil
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.same(loop.spawn.calls[1].refs[2], {})
            end)

            it("should call loop.spawn with specified timeout", function()
                generator_args.timeout = 500
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.same(loop.spawn.calls[1].refs[3].timeout, 500)
            end)

            it("should call loop.spawn with default timeout", function()
                generator_args.timeout = nil
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.same(loop.spawn.calls[1].refs[3].timeout, c.get().default_timeout)
            end)

            it("should call loop.spawn with the result of the specified cwd function", function()
                generator_args.cwd = function(params)
                    assert.same(params.root, root)
                    return "foo"
                end
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.same(loop.spawn.calls[1].refs[3].cwd, "foo")
            end)

            it("should call loop.spawn with default root as cwd if no cwd given", function()
                generator_args.cwd = nil
                local generator = helpers.generator_factory(generator_args)

                generator.fn({})

                assert.same(loop.spawn.calls[1].refs[3].cwd, root)
            end)

            it("should call loop.spawn with buffer content as string when to_stdin = true", function()
                test_utils.edit_test_file("test-file.lua")
                local params = { bufnr = vim.api.nvim_get_current_buf() }
                generator_args.to_stdin = true

                local generator = helpers.generator_factory(generator_args)
                generator.fn(params)

                local input = loop.spawn.calls[1].refs[3].input
                assert.equals(input, 'print("I am a test file!")\n')
            end)

            describe("to_temp_file", function()
                local cleanup = stub.new()

                local params
                before_each(function()
                    loop.temp_file.returns("temp-path", cleanup)

                    params = { content = { "buffer content" }, bufname = "mock-file.lua" }
                    generator_args.to_temp_file = true
                    generator_args.args = { "$FILENAME" }

                    local generator = helpers.generator_factory(generator_args)
                    generator.fn(params)
                end)
                after_each(function()
                    cleanup:clear()
                end)

                it("should call loop.temp_file with content and file extension", function()
                    assert.stub(loop.temp_file).was_called_with("buffer content", "lua")
                end)

                it("should replace $FILENAME arg with temp path", function()
                    assert.same(loop.spawn.calls[1].refs[2], { "temp-path" })
                end)

                it("should assign temp_path to params", function()
                    assert.equals(params.temp_path, "temp-path")
                end)

                it("should call cleanup callback in on_stdout_end", function()
                    local on_stdout_end = loop.spawn.calls[1].refs[3].on_stdout_end

                    on_stdout_end()

                    assert.stub(cleanup).was_called()
                end)
            end)

            describe("from_temp_file", function()
                local cleanup = stub.new()
                stub(vim.loop, "fs_open")
                stub(vim.loop, "fs_fstat")
                stub(vim.loop, "fs_read")
                stub(vim.loop, "fs_close")

                local mock_fd = 99
                local mock_stat = { size = 100 }

                local params
                local on_stdout_end
                before_each(function()
                    loop.temp_file.returns("temp-path", cleanup)
                    vim.loop.fs_open.returns(99)
                    vim.loop.fs_fstat.returns(mock_stat)

                    generator_args.to_temp_file = true
                    generator_args.from_temp_file = true

                    local generator = helpers.generator_factory(generator_args)
                    params = {}
                    generator.fn(params)
                    on_stdout_end = loop.spawn.calls[1].refs[3].on_stdout_end
                end)
                after_each(function()
                    vim.loop.fs_open:clear()
                    vim.loop.fs_fstat:clear()
                    cleanup:clear()
                end)

                it("should call vim.loop methods", function()
                    on_stdout_end()

                    assert.stub(vim.loop.fs_open).was_called_with("temp-path", "r", 438)
                    assert.stub(vim.loop.fs_fstat).was_called_with(mock_fd)
                    assert.stub(vim.loop.fs_read).was_called_with(mock_fd, mock_stat.size, 0)
                    assert.stub(vim.loop.fs_close).was_called_with(mock_fd)
                end)

                it("should set params.output to temp file content", function()
                    vim.loop.fs_read.returns("content")

                    on_stdout_end()

                    assert.equals(params.output, "content")
                end)
            end)

            describe("use_cache", function()
                it("should call wrapper with cached output and return", function()
                    s.get_cache.returns("cached")
                    generator_args.use_cache = true

                    helpers.generator_factory(generator_args).fn({})

                    assert.stub(loop.spawn).was_not_called()
                    assert.equals(on_output.calls[1].refs[1].output, "cached")
                    assert.equals(on_output.calls[1].refs[1]._null_ls_cached, true)
                end)

                it("should pass cached output as output when from_stderr is true", function()
                    s.get_cache.returns("cached")
                    generator_args.use_cache = true
                    generator_args.from_stderr = true

                    helpers.generator_factory(generator_args).fn({})

                    assert.equals(on_output.calls[1].refs[1].output, "cached")
                    assert.equals(on_output.calls[1].refs[1]._null_ls_cached, true)
                end)

                it("should call spawn when cache is empty", function()
                    s.get_cache.returns(nil)
                    generator_args.use_cache = true

                    local generator = helpers.generator_factory(generator_args)
                    generator.fn({})

                    assert.stub(loop.spawn).was_called()
                end)
            end)
        end)

        describe("wrapper", function()
            it("should set params.output and call on_output with params and done", function()
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, "output")

                assert.equals(on_output.calls[1].refs[1].output, "output")
                assert.equals(on_output.calls[1].refs[2], done)
            end)

            it("should set output to error_output and error_output to nil if from_stderr = true", function()
                generator_args.from_stderr = true
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper("error output", nil)

                assert.equals(on_output.calls[1].refs[1].output, "error output")
                assert.equals(on_output.calls[1].refs[2], done)
            end)

            it("should ignore error output if ignore_stderr = true", function()
                generator_args.ignore_stderr = true
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper("error output", "normal output")

                assert.equals(on_output.calls[1].refs[1].output, "normal output")
                assert.equals(on_output.calls[1].refs[2], done)
            end)

            it("should not override params.output if already set", function()
                local params = { output = "original output" }
                local generator = helpers.generator_factory(generator_args)
                generator.fn(params, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, "new output")

                assert.equals(on_output.calls[1].refs[1].output, "original output")
                assert.equals(on_output.calls[1].refs[2], done)
            end)

            it("should catch error thrown in handle_output", function()
                generator_args.on_output = function()
                    error("handle_output error")
                end

                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, "output")

                local generator_err = done.calls[1].refs[1]._generator_err
                assert.truthy(generator_err)
                assert.truthy(generator_err:find("handle_output error"))
            end)

            it("should pass error to done if error_output exists and format ~= raw", function()
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper("error output", nil)

                local generator_err = done.calls[1].refs[1]._generator_err
                assert.truthy(generator_err)
                assert.truthy(generator_err:find("error output"))
            end)

            it("should set params.err if format == raw", function()
                generator_args.format = "raw"
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper("error output", nil)

                assert.equals(on_output.calls[1].refs[1].err, "error output")
                assert.equals(on_output.calls[1].refs[2], done)
            end)

            it("should set params.err if format == json_raw", function()
                generator_args.format = "json_raw"
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper("error output", nil)

                assert.truthy(on_output.calls[1].refs[1].err:match("bad argument"))
            end)

            it("should call json_output_wrapper and return if format == json", function()
                generator_args.format = "json"
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, vim.fn.json_encode({ key = "val" }))

                assert.same(on_output.calls[1].refs[1].output, { key = "val" })
            end)

            it("should call json_output_wrapper and return if format == json_raw", function()
                generator_args.format = "json_raw"
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, vim.fn.json_encode({ key = "val" }))

                assert.same(on_output.calls[1].refs[1].output, { key = "val" })
            end)

            it("should call line_output_wrapper and return if format == line", function()
                generator_args.format = "line"
                local generator = helpers.generator_factory(generator_args)
                generator.fn({}, done)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, "output")

                assert.equals(on_output.calls[1].refs[1], "output")
                assert.equals(on_output.calls[1].refs[2].output, "output")
            end)

            it("should call set_cache with bufnr, command, and output if use_cache is true", function()
                local params = { bufnr = 1 }
                generator_args.use_cache = true
                helpers.generator_factory(generator_args).fn(params)

                local wrapper = loop.spawn.calls[1].refs[3].handler
                wrapper(nil, "output")

                assert.stub(s.set_cache).was_called_with(params.bufnr, generator_args.command, "output")
            end)
        end)
    end)

    describe("formatter_factory", function()
        local opts
        before_each(function()
            stub(helpers, "generator_factory")
            opts = { key = "val" }
        end)

        after_each(function()
            helpers.generator_factory:clear()
            helpers.generator_factory:revert()
        end)

        it("should call generator_factory with default opts", function()
            helpers.formatter_factory(opts)

            assert.stub(helpers.generator_factory).was_called_with(opts)
            assert.equals(helpers.generator_factory.calls[1].refs[1].ignore_stderr, true)
            assert.truthy(helpers.generator_factory.calls[1].refs[1].on_output)
        end)

        it("should not set ignore_stderr when explicitly set to false", function()
            opts.ignore_stderr = false

            helpers.formatter_factory(opts)

            assert.equals(helpers.generator_factory.calls[1].refs[1].ignore_stderr, false)
        end)

        it("should set from_temp_file if to_temp_file = true", function()
            opts.to_temp_file = true

            helpers.formatter_factory(opts)

            assert.equals(helpers.generator_factory.calls[1].refs[1].from_temp_file, true)
        end)

        describe("on_output", function()
            local formatter_done = stub.new()
            after_each(function()
                formatter_done:clear()
            end)

            it("should call done and return if no output", function()
                helpers.formatter_factory(opts)
                local on_formatter_output = helpers.generator_factory.calls[1].refs[1].on_output

                on_formatter_output({}, formatter_done)

                assert.stub(formatter_done).was_called()
            end)

            it("should call done with edit object", function()
                helpers.formatter_factory(opts)
                local on_formatter_output = helpers.generator_factory.calls[1].refs[1].on_output

                on_formatter_output({
                    output = "new text",
                    content = { "line1", "line" },
                }, formatter_done)

                assert.stub(formatter_done).was_called_with({
                    {
                        row = 1,
                        col = 1,
                        end_row = 3,
                        end_col = 1,
                        text = "new text",
                    },
                })
            end)
        end)
    end)

    describe("make_builtin", function()
        local opts = {
            method = "mockMethod",
            name = "mock-builtin",
            filetypes = { "lua" },
            factory = stub.new(),
            generator_opts = {
                key = "val",
                other_key = "other_val",
                nested = { nested_key = "nested_val", other_nested = "original_val" },
                args = { "first", "second" },
            },
        }
        local mock_generator = {
            fn = function()
                print("I am a generator")
            end,
        }

        local builtin
        before_each(function()
            opts.factory.returns(mock_generator)
            builtin = helpers.make_builtin(opts)
        end)

        after_each(function()
            opts.factory:clear()
        end)

        it("should return builtin with assigned opts", function()
            assert.equals(builtin.method, opts.method)
            assert.equals(builtin.filetypes, opts.filetypes)
            assert.are.same(builtin._opts, opts.generator_opts)
        end)

        describe("with", function()
            it("should create copy", function()
                local copy = builtin.with({ filetypes = { "txt" } })

                assert.not_same(builtin, copy)
            end)

            it("should override filetypes", function()
                local copy = builtin.with({ filetypes = { "txt" } })

                assert.same(copy.filetypes, { "txt" })
            end)

            it("should override method", function()
                local copy = builtin.with({ method = "newMethod" })

                assert.equals(copy.method, "newMethod")
            end)

            it("should set disabled filetypes", function()
                local copy = builtin.with({ disabled_filetypes = { "teal" } })

                assert.same(copy.disabled_filetypes, { "teal" })
            end)

            it("should override values on opts", function()
                local copy = builtin.with({ timeout = 5000 })

                assert.equals(copy._opts.timeout, 5000)
            end)

            it("should override single nested value", function()
                local copy = builtin.with({ nested = { nested_key = "new_val" } })

                assert.equals(copy._opts.nested.nested_key, "new_val")
                assert.equals(copy._opts.nested.other_nested, "original_val")
            end)

            it("should extend args with extra_args table", function()
                local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
                -- Multiple calls should yield the same results
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
            end)

            it("should extend args with extra_args function", function()
                local copy = builtin.with({
                    extra_args = function()
                        return { "user_first", "user_second" }
                    end,
                })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
            end)

            it("should keep original args if extra_args returns nil", function()
                local copy = builtin.with({
                    extra_args = function()
                        return nil
                    end,
                })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "first", "second" })
                assert.are.same(copy._opts.args(), { "first", "second" })
            end)

            it("should set args to extra_args if args is nil", function()
                local test_opts = {
                    method = "mockMethod",
                    name = "mock-builtin",
                    filetypes = { "lua" },
                    generator_opts = {
                        args = nil,
                    },
                }
                builtin = helpers.make_builtin(test_opts)
                local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "user_first", "user_second" })
            end)

            it("should set args to extra_args if args returns nil", function()
                local test_opts = {
                    method = "mockMethod",
                    name = "mock-builtin",
                    filetypes = { "lua" },
                    generator_opts = {
                        args = function()
                            return nil
                        end,
                    },
                }
                builtin = helpers.make_builtin(test_opts)
                local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "user_first", "user_second" })
            end)

            it("should extend args with extra_args, but keep '-' arg last", function()
                -- local test_opts = vim.deep_copy(opts) stack overflows
                local test_opts = {
                    method = "mockMethod",
                    name = "mock-builtin",
                    filetypes = { "lua" },
                    generator_opts = {
                        args = { "first", "second", "-" },
                    },
                }
                builtin = helpers.make_builtin(test_opts)
                local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

                assert.equals(type(copy._opts.args), "function")
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second", "-" })
                -- Multiple calls should yield the same results
                assert.are.same(copy._opts.args(), { "first", "second", "user_first", "user_second", "-" })
            end)

            it("should wrap builtin with condition and return copy if callback returns true", function()
                local wrapped_copy = builtin.with({
                    condition = function()
                        return true
                    end,
                })

                assert.equals(type(wrapped_copy), "function")

                assert.is_not.equals(wrapped_copy(), builtin)
            end)

            it("should retrun nil if callback returns false", function()
                local wrapped_copy = builtin.with({
                    condition = function()
                        return false
                    end,
                })

                assert.falsy(wrapped_copy())
            end)
        end)

        describe("index metatable", function()
            it("should call factory function with opts and return", function()
                local generator = builtin.generator

                assert.stub(opts.factory).was_called_with(builtin._opts)
                assert.equals(generator, mock_generator)
            end)

            it("should call factory function with override opts", function()
                local result = builtin.with({ timeout = 5000 })

                local _ = result.generator

                assert.equals(opts.factory.calls[1].refs[1].timeout, 5000)
            end)

            it("should use default factory function to assign opts to generator", function()
                local default_opts = { generator = {}, generator_opts = { test_key = "test-val" } }
                builtin = helpers.make_builtin(default_opts)

                local generator = builtin.generator

                assert.same(generator, default_opts.generator)
            end)
        end)
    end)
end)
