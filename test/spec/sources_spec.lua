local match = require("luassert.match")
local stub = require("luassert.stub")
local spy = require("luassert.spy")
local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local sources = require("null-ls.sources")

local uv = vim.loop

local register = function(method, generators, force)
    sources.register({{method = method, generators = generators}}, force)
end

local assert_length = function(tbl, length)
    assert.equals(vim.tbl_count(tbl), length)
end

describe("sources", function()
    after_each(function() sources.reset() end)

    local method = "textDocument/codeAction"
    local mock_generators = {
        {fn = function() print("I am a generator!") end},
        {fn = function() print("Me too, I guess") end}
    }

    describe("register", function()
        it("should register generators for method", function()
            register(method, mock_generators)

            assert_length(sources.get_generators(method),
                          vim.tbl_count(mock_generators))
        end)

        it(
            "should register additional generators when method generators already exist",
            function()
                local new_generators = {
                    {fn = function()
                        print("I am a new generator")
                    end}, {fn = function() print("Me too") end}
                }

                register(method, mock_generators)
                register(method, new_generators)

                assert_length(sources.get_generators(method), vim.tbl_count(
                                  mock_generators) +
                                  vim.tbl_count(new_generators))
            end)
    end)

    describe("get_generators", function()
        it("should return empty table when no generators have been registered",
           function()
            assert.equals(vim.tbl_count(sources.get_generators()), 0)
        end)

        it("should return method generators when method is specified",
           function()
            register(method, mock_generators)

            assert_length(sources.get_generators(method),
                          vim.tbl_count(mock_generators))
        end)

        it("should return all generators when method is not specified",
           function()
            register(method, mock_generators)

            local all_generators = sources.get_generators()
            assert_length(all_generators, 1)
            assert_length(all_generators[method], vim.tbl_count(mock_generators))
        end)
    end)

    describe("reset", function()
        it("should reset all generators when method is not specified",
           function()
            register(method, mock_generators)

            sources.reset()

            assert_length(sources.get_generators(), 0)
        end)

        it("should reset method generators when method is not specified",
           function()
            local other_method = "workspace/applyEdit"
            register(method, mock_generators)
            register(other_method, mock_generators, true)

            sources.reset(method)

            local all_generators = sources.get_generators()
            assert_length(all_generators[method], 0)
            assert_length(all_generators[other_method],
                          vim.tbl_count(mock_generators))
        end)

        it("should echo warning on unsupported method", function()
            stub(u, "echo")
            local unsupported_method = "workspace/thisWillNotWork"

            register(unsupported_method, mock_generators)

            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match(
                                                    "not supported"))
            assert.equals(sources.get_generators()[unsupported_method], nil)
        end)
    end)

    a.tests.describe("run_generators", function()
        local filetype_matches_spy = spy(u.filetype_matches)
        after_each(function() filetype_matches_spy:clear() end)

        local mock_result = {
            title = "Mock action",
            action = function() print("I'm a mock action") end
        }
        local mock_params = {method = method, ft = "lua"}

        local mock_sync_generator = {fn = function() return {mock_result} end}
        local mock_filetype_generator = {
            fn = function() return {mock_result} end,
            filetypes = {"txt"}
        }
        local mock_async_generator = {
            fn = function(_, callback)
                local timer = uv.new_timer()
                timer:start(5, 0, function()
                    timer:stop()
                    timer:close()
                    callback({mock_result})
                end)
            end,
            async = true
        }
        local mock_error_generator = {
            fn = function() error("something went wrong") end
        }

        it("should immediately return when method has no registered generators",
           function()
            register(method, {mock_sync_generator})

            local results = a.await(sources.run_generators(
                                        {method = "someRandomMethod"}))

            assert.equals(vim.tbl_count(results), 0)
            assert.spy(filetype_matches_spy).was_not_called()
        end)

        it("should get result from sync generator", function()
            register(method, {mock_sync_generator})

            local results = a.await(sources.run_generators(mock_params))

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should get result from async generator", function()
            register(method, {mock_async_generator})

            local results = a.await(sources.run_generators(mock_params))

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].title, mock_result.title)
        end)

        it("should not get result when filetype does not match", function()
            register(method, {mock_filetype_generator})

            local results = a.await(sources.run_generators(mock_params))

            assert.equals(vim.tbl_count(results), 0)
        end)

        it("should echo error message when generator throws an error",
           function()
            stub(u, "echo")
            register(method, {mock_error_generator})

            local results = a.await(sources.run_generators(mock_params))

            assert.equals(vim.tbl_count(results), 0)
            assert.stub(u.echo).was_called_with("WarningMsg", match.has_match(
                                                    "something went wrong"))
        end)

        it("should run postprocess on result", function()
            register(method, {mock_sync_generator})
            local postprocess = function(result)
                result.param = "mockParam"
            end

            local results = a.await(sources.run_generators(mock_params,
                                                           postprocess))

            assert.equals(vim.tbl_count(results), 1)
            assert.equals(results[1].param, "mockParam")
        end)
    end)
end)
