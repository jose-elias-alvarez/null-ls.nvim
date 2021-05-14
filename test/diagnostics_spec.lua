local a = require("plenary.async_lib")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local loop = require("null-ls.loop")

local u = require("null-ls.utils")
local handlers = require("null-ls.handlers")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local api = vim.api

local get_bufname = function()
    return api.nvim_buf_get_name(api.nvim_get_current_buf())
end

describe("diagnostics", function()
    _G._TEST = true
    local diagnostics = require("null-ls.diagnostics")

    describe("attach", function()
        stub(vim, "schedule_wrap")
        stub(api, "nvim_buf_attach")
        stub(loop, "timer")
        stub(a, "await")
        stub(u, "make_params")
        stub(handlers, "diagnostics")
        stub(sources, "run_generators")

        after_each(function()
            vim.schedule_wrap:clear()
            api.nvim_buf_attach:clear()
            loop.timer:clear()
            a.await:clear()
            u.make_params:clear()
            handlers.diagnostics:clear()
            sources.run_generators:clear()

            diagnostics._reset()
        end)

        local callback = function() print("I am a callback") end

        it("should set attached[bufname] to true", function()
            vim.schedule_wrap.returns(callback)

            diagnostics.attach()

            assert.equals(diagnostics._get_attached()[get_bufname()], true)
        end)

        it("should create timer with args and callback", function()
            vim.schedule_wrap.returns(callback)

            diagnostics.attach()

            assert.stub(loop.timer).was_called_with(0, nil, true, callback)
        end)

        it("should call nvim_buf_attach with args", function()
            diagnostics.attach()

            local args = api.nvim_buf_attach.calls[1].refs

            assert.equals(args[1], api.nvim_get_current_buf())
            assert.equals(args[2], false)
            assert.truthy(args[3].on_lines)
            assert.truthy(args[3].on_detach)
        end)

        it("should not attach again if buffer is already attachd", function()
            diagnostics.attach()

            diagnostics.attach()

            assert.stub(api.nvim_buf_attach).was_called(1)
        end)

        describe("on_lines", function()
            it("should call timer.restart with debounce time", function()
                local restart = spy.new()
                loop.timer.returns({restart = restart})

                diagnostics.attach()
                local opts = api.nvim_buf_attach.calls[1].refs[3]
                opts.on_lines()

                assert.spy(restart).was_called_with(250)
            end)
        end)

        describe("on_detach", function()
            it("should call timer.stop and remove bufname from attached",
               function()
                local stop = spy.new()
                loop.timer.returns({stop = stop})

                diagnostics.attach()
                local opts = api.nvim_buf_attach.calls[1].refs[3]
                opts.on_detach()

                assert.spy(stop).was_called()
                assert.equals(diagnostics._get_attached()[get_bufname()], nil)
            end)
        end)
    end)

    describe("postprocess", function()
        it("should convert range when all positions are defined", function()
            local diagnostic = {row = 1, col = 5, end_row = 2, end_col = 6}

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = 6, line = 1},
                start = {character = 5, line = 0}
            })
        end)

        it("should convert range when row is missing", function()
            local diagnostic = {row = nil, col = 5, end_row = 2, end_col = 6}

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = 6, line = 1},
                start = {character = 5, line = 0}
            })
        end)

        it("should convert range when col is missing", function()
            local diagnostic = {row = 1, col = nil, end_row = 2, end_col = 6}

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = 6, line = 1},
                start = {character = 0, line = 0}
            })
        end)

        it("should convert range when end_row is missing", function()
            local diagnostic = {row = 1, col = 5, end_row = nil, end_col = 6}

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = 6, line = 0},
                start = {character = 5, line = 0}
            })
        end)

        it("should convert range when end_col is missing", function()
            local diagnostic = {row = 1, col = 5, end_row = 2, end_col = nil}

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = -1, line = 1},
                start = {character = 5, line = 0}
            })
        end)

        it("should convert range when all positions are missing", function()
            local diagnostic = {
                row = nil,
                col = nil,
                end_row = nil,
                end_col = nil
            }

            diagnostics._postprocess(diagnostic)

            assert.same(diagnostic.range, {
                ["end"] = {character = -1, line = 0},
                start = {character = 0, line = 0}
            })
        end)

        it("should keep diagnostic source when defined", function()
            local diagnostic = {
                row = 1,
                col = 5,
                end_row = 2,
                end_col = 6,
                source = "mock-source"
            }

            diagnostics._postprocess(diagnostic)

            assert.equals(diagnostic.source, "mock-source")
        end)

        it("should set default source when undefined", function()
            local diagnostic = {row = 1, col = 5, end_row = 2, end_col = 6}

            diagnostics._postprocess(diagnostic)

            assert.equals(diagnostic.source, "null-ls")
        end)
    end)

    describe("get_diagnostics", function()
        local bufnr = 5
        local mock_params = {uri = "mock URI"}
        before_each(function() u.make_params.returns(mock_params) end)

        it("should call make_params with method and bufnr", function()
            diagnostics._get_diagnostics(bufnr)

            assert.stub(u.make_params).was_called_with(methods.DIAGNOSTICS,
                                                       bufnr)
        end)

        it("should call run_generators with params and postprocess", function()
            diagnostics._get_diagnostics(bufnr)

            assert.stub(sources.run_generators).was_called_with(mock_params,
                                                                diagnostics._postprocess)
        end)

        it("should call handlers.diagnostics with diagnostics and uri",
           function()
            a.await.returns("diagnostics")

            diagnostics._get_diagnostics(bufnr)

            assert.stub(handlers.diagnostics).was_called_with(
                {diagnostics = "diagnostics", uri = mock_params.uri})
        end)
    end)
end)
