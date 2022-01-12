local stub = require("luassert.stub")
local mock = require("luassert.mock")

local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local uv = vim.loop

mock(require("null-ls.logger"), true)

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
        filetypes = { "text" },
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
    local mock_params, mock_opts
    local postprocess = stub.new()
    before_each(function()
        error_generator = {
            filetypes = { "lua" },
            fn = function()
                error("something went wrong")
            end,
        }
        mock_params = { method = method, ft = "lua" }
        mock_opts = { postprocess = postprocess }
    end)

    after_each(function()
        postprocess:clear()
        sources._reset()
    end)

    describe("run", function()
        local results, received = {}, false
        local callback
        before_each(function()
            callback = function(generator_results)
                received = true
                results = vim.list_extend(results, generator_results)
            end
        end)

        after_each(function()
            results = {}
            received = false
        end)

        local wait_for_results = function(count)
            vim.wait(50, function()
                return received and #results == (count or 0)
            end)
        end

        it("should return empty table when generators is empty", function()
            generators.run({}, mock_params, mock_opts, callback)
            wait_for_results()

            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should get result from sync generator", function()
            generators.run({ sync_generator }, mock_params, mock_opts, callback)

            wait_for_results(1)

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should get result from async generator", function()
            generators.run({ async_generator }, mock_params, mock_opts, callback)
            wait_for_results(1)

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should handle error thrown in sync generator", function()
            generators.run({ error_generator }, mock_params, mock_opts, callback)
            wait_for_results()

            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should handle error thrown in async generator", function()
            error_generator.async = true

            generators.run({ error_generator }, mock_params, mock_opts, callback)
            wait_for_results()

            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should handle error passed as _generator_err", function()
            error_generator.fn = function()
                return { _generator_err = "something went wrong" }
            end

            generators.run({ error_generator }, mock_params, mock_opts, callback)
            wait_for_results()

            assert.equals(error_generator._failed, true)
            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should call postprocess with result, params, and generator", function()
            generators.run({ sync_generator }, mock_params, mock_opts, callback)

            wait_for_results()

            assert.stub(postprocess).was_called_with(mock_result, mock_params, sync_generator)
        end)

        it("should call after_each with results, params, and generator", function()
            mock_opts.after_each = stub.new()

            generators.run({ sync_generator }, mock_params, mock_opts, callback)
            wait_for_results()

            assert.stub(mock_opts.after_each).was_called_with(results, mock_params, sync_generator)
        end)

        it("should skip generators that fail runtime_condition", function()
            generators.run({
                runtime_generator(false),
                runtime_generator(true),
            }, mock_params, mock_opts, callback)

            wait_for_results()

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should return an empty table if all runtime_conditions fail", function()
            generators.run({
                runtime_generator(false),
                runtime_generator(false),
            }, mock_params, mock_opts, callback)

            wait_for_results()

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

        local results, callback
        before_each(function()
            results = {}
            callback = function(generator_results)
                results = vim.list_extend(results, generator_results)
            end
        end)

        it("should run generators sequentially", function()
            generators.run_sequentially({ first_generator, second_generator }, function()
                mock_params.count = mock_params.count and mock_params.count + 1 or 1
                return mock_params
            end, mock_opts, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(#results, 2)
            assert.same(results[1], "first")
            assert.same(results[2], "second")
        end)

        it("should run generators in order", function()
            generators.run_sequentially({ second_generator, first_generator }, function()
                return mock_params
            end, mock_opts, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(#results, 2)
            assert.same(results[1], "second")
            assert.same(results[2], "first")
        end)

        it("should call make_params once at start and once for each run", function()
            local count = 0
            generators.run_sequentially({ first_generator, second_generator }, function()
                count = count + 1
                return mock_params
            end, mock_opts, callback)

            vim.wait(50, function()
                return #results == 2
            end)

            assert.equals(count, 3)
        end)

        it("should return no results when generators is empty", function()
            generators.run_sequentially({}, function()
                return mock_params
            end, mock_opts, callback)

            vim.wait(50)

            assert.equals(#results, 0)
        end)
    end)

    describe("run_registered", function()
        local callback = stub.new()
        local after_each = stub.new()

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
            local mock_run_opts = {
                filetype = mock_params.ft,
                method = mock_params.method,
                params = mock_params,
                postprocess = postprocess,
                callback = callback,
                after_each = after_each,
            }

            generators.run_registered(mock_run_opts)

            assert.stub(run).was_called_with(
                generators.get_available(mock_run_opts.filetype, mock_run_opts.method),
                mock_run_opts.params,
                { postprocess = postprocess, after_each = after_each },
                mock_run_opts.callback
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
            local mock_run_opts = {
                filetype = mock_params.ft,
                method = mock_params.method,
                make_params = function()
                    return mock_params
                end,
                postprocess = postprocess,
                callback = callback,
                after_all = after_all,
            }

            generators.run_registered_sequentially(mock_run_opts)

            assert.stub(run_sequentially).was_called_with(
                generators.get_available(mock_run_opts.filetype, mock_run_opts.method),
                mock_run_opts.make_params,
                { postprocess = postprocess, after_all = after_all },
                mock_run_opts.callback
            )
        end)
    end)

    describe("get_available", function()
        it("should return empty table if no generators registered", function()
            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)

        it("should return empty table if no generators registered for filetype", function()
            register(method, wrong_fileytpe_generator, { "text" })

            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)

        it("should return generator copy with source id if registered for filetype", function()
            register(method, sync_generator, { "lua" })

            local available = generators.get_available("lua", method)

            local copy = vim.deepcopy(sync_generator)
            copy.source_id = 1
            assert.same(available, { copy })
        end)

        it("should exclude generator if failed flag is set", function()
            error_generator._failed = true
            register(method, error_generator, { "lua" })

            local available = generators.get_available("lua", method)

            assert.same(available, {})
        end)
    end)

    describe("can_run", function()
        it("should return false if no generators registered", function()
            local can_run = generators.can_run("lua", method)

            assert.equals(can_run, false)
        end)

        it("should return false if no generators registered for filetype", function()
            register(method, wrong_fileytpe_generator, { "text" })

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
