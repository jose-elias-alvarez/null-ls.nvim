local match = require("luassert.match")
local stub = require("luassert.stub")
local spy = require("luassert.spy")
local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local c = require("null-ls.config")

local uv = vim.loop

local register = function(method, generator, filetypes)
    c.register({
        method = method,
        generator = generator,
        filetypes = filetypes or { "lua" },
    })
end

describe("generators", function()
    local generators = require("null-ls.generators")
    local method = "textDocument/codeAction"

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
    local error_generator = {
        filetypes = { "lua" },
        fn = function()
            error("something went wrong")
        end,
    }

    local postprocess = stub.new()
    local mock_params
    before_each(function()
        mock_params = { method = method, ft = "lua", generators = {} }
    end)

    after_each(function()
        postprocess:clear()
        c.reset_sources()
    end)

    a.tests.describe("run", function()
        local echo = stub(u, "echo")
        local filetype_matches_spy = spy(u.filetype_matches)
        after_each(function()
            echo:clear()
            filetype_matches_spy:clear()
        end)

        local wrapped_run = a.wrap(generators.run, 4)

        it("should immediately return when method has no registered generators", function()
            mock_params.method = "someRandomMethod"

            local results = a.await(wrapped_run(nil, mock_params, postprocess))

            assert.equals(vim.tbl_count(results), 0)
            assert.spy(filetype_matches_spy).was_not_called()
        end)

        it("should get result from sync generator", function()
            local results = a.await(wrapped_run({ sync_generator }, mock_params, postprocess))

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should get result from async generator", function()
            local results = a.await(wrapped_run({ async_generator }, mock_params, postprocess))

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should not get result when filetype does not match", function()
            local results = a.await(wrapped_run({ wrong_fileytpe_generator }, mock_params, postprocess))

            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should echo error message when generator throws an error", function()
            local results = a.await(wrapped_run({ error_generator }, mock_params, postprocess))

            assert.equals(vim.tbl_count(results), 0)
            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match("something went wrong"))
        end)

        it("should call postprocess with result, params, and index", function()
            a.await(wrapped_run({ sync_generator }, mock_params, postprocess))

            assert.stub(postprocess).was_called_with(mock_result, mock_params, 1)
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

        it("should call run with registered generators", function()
            register(method, sync_generator, { "lua" })

            generators.run_registered(mock_params, postprocess, callback)

            assert.stub(run).was_called_with({ sync_generator }, mock_params, postprocess, callback)
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
