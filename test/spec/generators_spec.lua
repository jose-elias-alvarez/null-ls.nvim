local match = require("luassert.match")
local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local methods = require("null-ls.methods")
local sources = require("null-ls.sources")
local u = require("null-ls.utils")

local uv = vim.loop

local register = function(method, generator, filetypes)
    sources.register({
        method = method,
        generator = generator,
        filetypes = filetypes or { "lua" },
    })
end

describe("generators", function()
    local generators = require("null-ls.generators")
    local method = methods.internal.CODE_ACTION

    local mock_result = {
        title = "Mock action",
        action = function()
            print("I'm a mock action")
        end,
    }
    local sync_generator = {
        filetypes = { "lua" },
        fn = function()
            return { mock_result }
        end,
    }
    local async_generator = {
        filetypes = { "lua" },
        fn = function(_, callback)
            local timer = uv.new_timer()
            timer:start(5, 0, function()
                timer:stop()
                timer:close()
                callback({ mock_result })
            end)
        end,
        async = true,
    }
    local wrong_fileytpe_generator = {
        filetypes = { "txt" },
        fn = function()
            return { mock_result }
        end,
    }
    local runtime_generator = function(runtime_result)
        return {
            filetypes = { "lua" },
            opts = {
                runtime_condition = function()
                    return runtime_result
                end,
            },
            fn = function()
                return { mock_result }
            end,
        }
    end

    local error_generator
    local mock_params
    local postprocess = stub.new()
    before_each(function()
        error_generator = {
            filetypes = { "lua" },
            fn = function()
                error("something went wrong")
            end,
        }
        mock_params = { method = method, ft = "lua", generators = {} }
    end)

    after_each(function()
        postprocess:clear()
        sources.reset()
    end)

    a.tests.describe("run", function()
        local echo = stub(u, "echo")
        after_each(function()
            echo:clear()
        end)

        local wrapped_run = a.wrap(generators.run, 4)

        it("should return empty table when generators is empty", function()
            local results = wrapped_run({}, mock_params, postprocess)()

            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should get result from sync generator", function()
            local results = wrapped_run({ sync_generator }, mock_params, postprocess)()

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should get result from async generator", function()
            local results = wrapped_run({ async_generator }, mock_params, postprocess)()

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should handle error thrown in sync generator", function()
            local results = wrapped_run({ error_generator }, mock_params, postprocess)()

            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match("something went wrong"))
            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should handle error thrown in async generator", function()
            error_generator.async = true

            local results = wrapped_run({ error_generator }, mock_params, postprocess)()

            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match("something went wrong"))
            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should handle error passed as _generator_err", function()
            error_generator.fn = function()
                return { _generator_err = "something went wrong" }
            end

            local results = wrapped_run({ error_generator }, mock_params, postprocess)()

            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match("something went wrong"))
            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should call postprocess with result, params, and generator", function()
            wrapped_run({ sync_generator }, mock_params, postprocess)()

            assert.stub(postprocess).was_called_with(mock_result, mock_params, sync_generator)
        end)

        it("should skip generators that fail runtime_condition", function()
            local results =
                wrapped_run(
                    { runtime_generator(false), runtime_generator(true) },
                    mock_params,
                    postprocess
                )()

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should return an empty table if all runtime_conditions fail", function()
            local results = wrapped_run(
                { runtime_generator(false), runtime_generator(false) },
                mock_params,
                postprocess
            )()

            assert.equals(vim.tbl_count(results), 0)
        end)
    end)

    describe("run_sequentially", function()
        local first_generator = {
            filetypes = { "lua" },
            fn = function()
                return { "first" }
            end,
        }
        local second_generator = {
            filetypes = { "lua" },
            fn = function()
                return { "second" }
            end,
        }

        local callback, results
        before_each(function()
            results = {}
            callback = function(generator_results)
                table.insert(results, generator_results)
            end
        end)

        it("should run generators sequentially", function()
            generators.run_sequentially({ first_generator, second_generator }, function()
                mock_params.count = mock_params.count and mock_params.count + 1 or 1
                return mock_params
            end, postprocess, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(#results, 2)
            assert.same(results[1], { "first" })
            assert.same(results[2], { "second" })
        end)

        it("should run generators in order", function()
            generators.run_sequentially({ second_generator, first_generator }, function()
                return mock_params
            end, postprocess, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(#results, 2)
            assert.same(results[1], { "second" })
            assert.same(results[2], { "first" })
        end)

        it("should call make_params once for each run", function()
            local count = 0
            generators.run_sequentially({ first_generator, second_generator }, function()
                count = count + 1
                return mock_params
            end, postprocess, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(count, 2)
        end)

        it("should call after_all after running all generators", function()
            local after_all = stub.new()
            generators.run_sequentially({ first_generator, second_generator }, function()
                return mock_params
            end, postprocess, callback, after_all)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.stub(after_all).was_called(1)
        end)

        it("should return no results when generators is empty", function()
            generators.run_sequentially({}, function()
                return mock_params
            end, postprocess, callback)

            vim.wait(50)

            assert.equals(#results, 0)
        end)
    end)

    describe("run_registered", function()
        local callback = stub.new()

        local run
        before_each(function()
            run = stub.new(generators, "run")
        end)
        after_each(function()
            callback:clear()
            run:revert()
        end)

        it("should call run with available generators and opts", function()
            register(method, sync_generator, { "lua" })
            local mock_opts = {
                filetype = mock_params.ft,
                method = mock_params.method,
                params = mock_params,
                postprocess = postprocess,
                callback = callback,
            }

            generators.run_registered(mock_opts)

            assert.stub(run).was_called_with(
                generators.get_available(mock_opts.filetype, mock_opts.method),
                mock_opts.params,
                mock_opts.postprocess,
                mock_opts.callback,
                nil
            )
        end)

        it("should call run with available generators indexed by id", function()
            register(method, sync_generator, { "lua" })
            local mock_opts = {
                filetype = mock_params.ft,
                method = mock_params.method,
                params = mock_params,
                postprocess = postprocess,
                callback = callback,
                index_by_id = true,
            }

            generators.run_registered(mock_opts)

            assert.stub(run).was_called_with(
                generators.get_available(mock_opts.filetype, mock_opts.method, mock_opts.index_by_id),
                mock_opts.params,
                mock_opts.postprocess,
                mock_opts.callback,
                true
            )
        end)
    end)

    describe("run_registered_sequentially", function()
        local callback = stub.new()
        local after_all = stub.new()

        local run_sequentially
        before_each(function()
            run_sequentially = stub.new(generators, "run_sequentially")
        end)
        after_each(function()
            callback:clear()
            after_all:clear()
            run_sequentially:revert()
        end)

        it("should call run_sequentially with available generators and opts", function()
            register(method, sync_generator, { "lua" })
            local mock_opts = {
                filetype = mock_params.ft,
                method = mock_params.method,
                make_params = function()
                    return mock_params
                end,
                postprocess = postprocess,
                callback = callback,
                after_all = after_all,
            }

            generators.run_registered_sequentially(mock_opts)

            assert.stub(run_sequentially).was_called_with(
                { sync_generator },
                mock_opts.make_params,
                mock_opts.postprocess,
                mock_opts.callback,
                mock_opts.after_all
            )
        end)
    end)

    describe("get_available", function()
        it("should return empty table if no generators registered", function()
            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)

        it("should return empty table if no generators registered for filetype", function()
            register(method, wrong_fileytpe_generator, { "txt" })

            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)

        it("should return generator if registered for filetype", function()
            register(method, sync_generator, { "lua" })

            local available = generators.get_available("lua", method)

            assert.same(available, { sync_generator })
        end)

        it("should exclude generator if failed flag is set", function()
            error_generator._failed = true
            register(method, error_generator, { "lua" })

            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)

        it("should index generators by id if index_by_id is true", function()
            register(method, sync_generator, { "lua" })

            local available = generators.get_available("lua", method, true)

            local generator_id
            for id in pairs(available) do
                generator_id = id
                break
            end

            assert.same(available, { [generator_id] = sync_generator })
        end)
    end)

    describe("can_run", function()
        it("should return false if no generators registered", function()
            local can_run = generators.can_run("lua", method)

            assert.equals(can_run, false)
        end)

        it("should return false if no generators registered for filetype", function()
            register(method, wrong_fileytpe_generator, { "txt" })

            local can_run = generators.can_run("lua", method)

            assert.equals(can_run, false)
        end)

        it("should return true if generators registered for filetype", function()
            register(method, sync_generator, { "lua" })

            local can_run = generators.can_run("lua", method)

            assert.equals(can_run, true)
        end)
    end)
end)
