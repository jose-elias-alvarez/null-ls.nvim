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

    after_each(function()
        c.reset_sources()
    end)

    a.tests.describe("make_runner", function()
        local filetype_matches_spy = spy(u.filetype_matches)
        after_each(function()
            filetype_matches_spy:clear()
        end)

        local mock_result = {
            title = "Mock action",
            action = function()
                print("I'm a mock action")
            end,
        }
        local mock_params = { method = method, ft = "lua" }

        local mock_sync_generator = { fn = function()
            return { mock_result }
        end }
        local mock_filetype_generator = {
            fn = function()
                return { mock_result }
            end,
        }
        local mock_async_generator = {
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
        local mock_error_generator = {
            fn = function()
                error("something went wrong")
            end,
        }

        it("should immediately return when method has no registered generators", function()
            register(method, mock_sync_generator)

            local results = a.await(generators.make_runner({ method = "someRandomMethod" })())

            assert.equals(vim.tbl_count(results), 0)
            assert.spy(filetype_matches_spy).was_not_called()
        end)

        it("should get result from sync generator", function()
            register(method, mock_sync_generator)

            local results = a.await(generators.make_runner(mock_params)())

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should get result from async generator", function()
            register(method, mock_async_generator)

            local results = a.await(generators.make_runner(mock_params)())

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should not get result when filetype does not match", function()
            register(method, mock_filetype_generator, { "txt" })

            local results = a.await(generators.make_runner(mock_params)())

            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should echo error message when generator throws an error", function()
            stub(u, "echo")
            register(method, mock_error_generator)

            local results = a.await(generators.make_runner(mock_params)())

            assert.equals(vim.tbl_count(results), 0)
            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match("something went wrong"))
        end)

        it("should run postprocess on result", function()
            register(method, mock_sync_generator)
            local postprocess = function(result)
                result.param = "mockParam"
            end

            local results = a.await(generators.make_runner(mock_params, postprocess)())

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].param, "mockParam")
        end)
    end)
end)
