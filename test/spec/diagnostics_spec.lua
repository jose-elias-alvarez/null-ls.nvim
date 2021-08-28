local mock = require("luassert.mock")
local stub = require("luassert.stub")

local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local lsp = mock(vim.lsp, "true")

describe("diagnostics", function()
    local diagnostics = require("null-ls.diagnostics")
    local reset = function()
        s.reset()
        c.reset()
        for uri in pairs(diagnostics._tracked_buffers) do
            diagnostics._tracked_buffers[uri] = nil
        end
    end

    local mock_uri = "file:///mock-file"
    local mock_client_id = 999
    local mock_params
    before_each(function()
        mock_params = {
            textDocument = { uri = mock_uri },
            client_id = mock_client_id,
            method = methods.lsp.DID_OPEN,
        }
        u.make_params.returns(mock_params)
    end)

    after_each(function()
        reset()
    end)

    describe("handler", function()
        stub(u, "make_params")
        stub(generators, "run_registered")

        after_each(function()
            lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS]:clear()

            generators.run_registered:clear()
            u.make_params:clear()
        end)

        it("should clear cache when method is DID_CHANGE", function()
            s.get().cache[mock_uri] = "cache"
            mock_params.method = methods.lsp.DID_CHANGE

            diagnostics.handler(mock_params)

            assert.equals(s.get().cache[mock_uri], nil)
        end)

        it("should clear cache when method is DID_CLOSE", function()
            s.get().cache[mock_uri] = "cache"
            mock_params.method = methods.lsp.DID_CLOSE

            diagnostics.handler(mock_params)

            assert.equals(s.get().cache[mock_uri], nil)
        end)

        it("should call make_params with params and method", function()
            diagnostics.handler(mock_params)

            assert.stub(u.make_params).was_called_with(mock_params, methods.internal.DIAGNOSTICS)
        end)

        it("should send results of diagnostic generators to lsp handler", function()
            u.make_params.returns({ uri = mock_params.textDocument.uri })

            diagnostics.handler(mock_params)
            local callback = generators.run_registered.calls[1].refs[1].callback
            callback("diagnostics")

            assert.stub(lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS]).was_called_with(nil, nil, {
                diagnostics = "diagnostics",
                uri = mock_params.textDocument.uri,
            }, mock_client_id, nil, {})
        end)

        describe("postprocess", function()
            local postprocess, mock_diagnostic, mock_generator
            before_each(function()
                mock_diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = 2,
                    end_col = 6,
                    source = "source",
                    message = "message",
                    code = "code",
                }
                mock_generator = { opts = {} }
                u.make_params.returns({ uri = mock_params.textDocument.uri })

                diagnostics.handler(mock_params)
                postprocess = generators.run_registered.calls[1].refs[1].postprocess
            end)

            it("should convert range when all positions are defined", function()
                local diagnostic = { row = 1, col = 5, end_row = 2, end_col = 6 }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = 5, line = 1 },
                    start = { character = 4, line = 0 },
                })
            end)

            it("should convert range when row is missing", function()
                local diagnostic = {
                    row = nil,
                    col = 5,
                    end_row = 2,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = 5, line = 1 },
                    start = { character = 4, line = 0 },
                })
            end)

            it("should convert range when col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = nil,
                    end_row = 2,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = 5, line = 1 },
                    start = { character = 0, line = 0 },
                })
            end)

            it("should convert range when end_row is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = nil,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = 5, line = 0 },
                    start = { character = 4, line = 0 },
                })
            end)

            it("should convert range when end_col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = 2,
                    end_col = nil,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = -1, line = 1 },
                    start = { character = 4, line = 0 },
                })
            end)

            it("should convert range when all positions are missing", function()
                local diagnostic = {
                    row = nil,
                    col = nil,
                    end_row = nil,
                    end_col = nil,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.same(diagnostic.range, {
                    ["end"] = { character = -1, line = 0 },
                    start = { character = 0, line = 0 },
                })
            end)

            it("should keep diagnostic source when defined", function()
                postprocess(mock_diagnostic, mock_params, { opts = {} })

                assert.equals(mock_diagnostic.source, "source")
            end)

            it("should set source from generator command", function()
                mock_diagnostic.source = nil

                postprocess(mock_diagnostic, mock_params, { opts = { command = "generator-source" } })

                assert.equals(mock_diagnostic.source, "generator-source")
            end)

            it("should set default source when undefined in diagnostic and generator", function()
                mock_diagnostic.source = nil

                postprocess(mock_diagnostic, mock_params, { opts = {} })

                assert.equals(mock_diagnostic.source, "null-ls")
            end)

            it("should return message with default format", function()
                postprocess(mock_diagnostic, mock_params, { opts = {} })

                assert.equals(mock_diagnostic.message, "message")
            end)

            it("should format message from global format", function()
                c._set({ diagnostics_format = "[#{c}] #{m} (#{s})" })

                postprocess(mock_diagnostic, mock_params, { opts = {} })

                assert.equals(mock_diagnostic.message, "[code] message (source)")
            end)

            it("should format message from generator format", function()
                postprocess(mock_diagnostic, mock_params, {
                    opts = { diagnostics_format = "#{c}! #{m} [#{s}]" },
                })

                assert.equals(mock_diagnostic.message, "code! message [source]")
            end)
        end)

        describe("tracking", function()
            it("should initialize tracking", function()
                diagnostics.handler(mock_params)

                local tracked = diagnostics._tracked_buffers[mock_uri]
                assert.truthy(tracked)
                assert.same(tracked, { count = 1, last_ran = 1, params = mock_params })
            end)

            it("should schedule run on InsertLeave", function()
                diagnostics.handler(mock_params)

                assert.equals(
                    vim.fn.exists(string.format("#NullLsInsertLeave%s#InsertLeave", vim.uri_to_bufnr(mock_uri))),
                    1
                )
            end)

            it("should increment count and last_ran", function()
                diagnostics.handler(mock_params)

                diagnostics.handler(mock_params)

                local tracked = diagnostics._tracked_buffers[mock_uri]
                assert.equals(tracked.count, 2)
                assert.equals(tracked.last_ran, 2)
            end)

            it("should clear tracking on DID_CLOSE", function()
                mock_params.method = methods.lsp.DID_CLOSE

                diagnostics.handler(mock_params)

                local tracked = diagnostics._tracked_buffers[mock_uri]
                assert.equals(tracked, nil)
            end)

            it("should clear scheduled run on DID_CLOSE", function()
                diagnostics.handler(mock_params)

                mock_params.method = methods.lsp.DID_CLOSE
                diagnostics.handler(mock_params)

                assert.equals(
                    vim.fn.exists(string.format("#NullLsInsertLeave%s#InsertLeave", vim.uri_to_bufnr(mock_uri))),
                    0
                )
            end)
        end)

        describe("mode", function()
            before_each(function()
                stub(diagnostics, "run")
                stub(vim.api, "nvim_get_mode")
            end)
            after_each(function()
                diagnostics.run:revert()
                vim.api.nvim_get_mode:revert()
            end)

            it("should call run with uri if not in insert mode", function()
                vim.api.nvim_get_mode.returns({ mode = "n" })

                diagnostics.handler(mock_params)

                assert.stub(diagnostics.run).was_called_with(mock_uri)
            end)

            it("should save params to state and not call run if in insert mode", function()
                vim.api.nvim_get_mode.returns({ mode = "i" })

                diagnostics.handler(mock_params)

                assert.stub(diagnostics.run).was_not_called()
            end)
        end)
    end)

    describe("run", function()
        local mock_tracked
        before_each(function()
            mock_tracked = { last_ran = nil, count = 1, params = {} }
        end)

        it("should not run if uri is not tracked", function()
            diagnostics.run(mock_uri)

            assert.stub(generators.run_registered).was_not_called()
        end)

        it("should not run if last_ran == count", function()
            mock_tracked.last_ran = mock_tracked.count
            diagnostics._tracked_buffers[mock_uri] = mock_tracked

            diagnostics.run(mock_uri)

            assert.stub(generators.run_registered).was_not_called()
        end)

        it("should run if last_ran is nil", function()
            diagnostics._tracked_buffers[mock_uri] = mock_tracked

            diagnostics.run(mock_uri)

            assert.stub(generators.run_registered).was_called()
        end)

        it("should run if count is higher than last_ran", function()
            mock_tracked.last_ran = 1
            mock_tracked.count = 2
            diagnostics._tracked_buffers[mock_uri] = mock_tracked

            diagnostics.run(mock_uri)

            assert.stub(generators.run_registered).was_called()
        end)

        it("should set last_ran to count on run", function()
            diagnostics._tracked_buffers[mock_uri] = mock_tracked

            diagnostics.run(mock_uri)

            assert.equals(mock_tracked.last_ran, mock_tracked.count)
        end)
    end)
end)
