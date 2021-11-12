local mock = require("luassert.mock")
local stub = require("luassert.stub")

local methods = require("null-ls.methods")
local generators = require("null-ls.generators")
local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")

local lsp = mock(vim.lsp, "true")
local diagnostic_api = mock(vim.diagnostic, "true")

describe("diagnostics", function()
    local diagnostics = require("null-ls.diagnostics")

    describe("handler", function()
        stub(s, "clear_cache")
        stub(u, "make_params")
        stub(generators, "run_registered")

        local mock_uri = "file:///mock-file"
        local mock_client_id = 999
        local mock_handler = stub.new()
        local mock_client = {
            name = "null-ls",
            id = mock_client_id,
            handlers = { [methods.lsp.PUBLISH_DIAGNOSTICS] = mock_handler },
        }

        local mock_params
        before_each(function()
            mock_params = {
                textDocument = { uri = mock_uri, version = 1 },
                client_id = mock_client_id,
                method = methods.lsp.DID_OPEN,
            }
            u.make_params.returns(mock_params)
            lsp.get_active_clients.returns({ mock_client })
        end)

        after_each(function()
            mock_handler:clear()
            s.clear_cache:clear()
            generators.run_registered:clear()
            u.make_params:clear()

            s.reset()
            c.reset()
        end)

        it("should call clear_cache with uri when method is DID_CLOSE", function()
            mock_params.method = methods.lsp.DID_CLOSE

            diagnostics.handler(mock_params)

            assert.stub(s.clear_cache).was_called_with(mock_params.textDocument.uri)
        end)

        it("should call clear_cache with uri when method is DID_CHANGE", function()
            mock_params.method = methods.lsp.DID_CHANGE

            diagnostics.handler(mock_params)

            assert.stub(s.clear_cache).was_called_with(mock_params.textDocument.uri)
        end)

        it("should call make_params with params and method", function()
            diagnostics.handler(mock_params)

            assert.stub(u.make_params).was_called_with(mock_params, methods.internal.DIAGNOSTICS)
        end)

        describe("handler", function()
            describe("LSP handler", function()
                before_each(function()
                    c._set({ _use_lsp_handler = true })
                    generators.run_registered:clear()
                    mock_handler:clear()
                end)

                it("should send results of diagnostic generators to lsp handler", function()
                    u.make_params.returns({ uri = mock_params.textDocument.uri })

                    diagnostics.handler(mock_params)
                    local callback = generators.run_registered.calls[1].refs[1].callback
                    callback("diagnostics")

                    assert.stub(mock_handler).was_called_with(nil, {
                        diagnostics = "diagnostics",
                        uri = mock_params.textDocument.uri,
                    }, {
                        method = methods.lsp.PUBLISH_DIAGNOSTICS,
                        client_id = mock_client_id,
                        bufnr = vim.uri_to_bufnr(mock_uri),
                    })
                end)

                describe("changedtick tracking", function()
                    it("should call handler on each callback if buffer did not change", function()
                        diagnostics.handler(mock_params)
                        diagnostics.handler(mock_params)

                        generators.run_registered.calls[1].refs[1].callback("diagnostics 1")
                        generators.run_registered.calls[2].refs[1].callback("diagnostics")

                        assert.stub(mock_handler).was_called(2)
                    end)

                    it("should call handler only once if buffer changed in between callbacks", function()
                        diagnostics.handler(mock_params)
                        local new_params = vim.deepcopy(mock_params)
                        new_params.textDocument.version = 9999
                        diagnostics.handler(new_params)

                        generators.run_registered.calls[1].refs[1].callback("diagnostics")
                        generators.run_registered.calls[2].refs[1].callback("diagnostics")

                        assert.stub(mock_handler).was_called(1)
                    end)
                end)
            end)

            describe("API handler", function()
                local mock_diagnostics = { [1] = "diagnostics", [2] = "more diagnostics" }
                local mock_bufnr = vim.uri_to_bufnr(mock_uri)
                before_each(function()
                    c.reset()
                end)

                it("should send results of diagnostic generators to API handler", function()
                    diagnostics.handler(mock_params)

                    local callback = generators.run_registered.calls[1].refs[1].callback
                    callback(mock_diagnostics)

                    assert.stub(diagnostic_api.set).was_called(#mock_diagnostics)
                    for id in pairs(mock_diagnostics) do
                        assert.stub(vim.diagnostic.set).was_called_with(
                            diagnostics.namespaces[id],
                            mock_bufnr,
                            mock_diagnostics[id]
                        )
                    end
                end)
            end)
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

            describe("LSP range", function()
                before_each(function()
                    c._set({ _use_lsp_handler = true })
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
                        ["end"] = { character = 0, line = 1 },
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
                        ["end"] = { character = 0, line = 1 },
                        start = { character = 0, line = 0 },
                    })
                end)
            end)

            describe("API range", function()
                before_each(function()
                    c.reset()
                end)

                it("should convert range when all positions are defined", function()
                    local diagnostic = { row = 1, col = 5, end_row = 2, end_col = 6 }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 1)
                    assert.equals(diagnostic.col, 4)
                    assert.equals(diagnostic.end_col, 5)
                end)

                it("should convert range when row is missing", function()
                    local diagnostic = {
                        row = nil,
                        col = 5,
                        end_row = 2,
                        end_col = 6,
                    }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 1)
                    assert.equals(diagnostic.col, 4)
                    assert.equals(diagnostic.end_col, 5)
                end)

                it("should convert range when col is missing", function()
                    local diagnostic = {
                        row = 1,
                        col = nil,
                        end_row = 2,
                        end_col = 6,
                    }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 1)
                    assert.equals(diagnostic.col, 0)
                    assert.equals(diagnostic.end_col, 5)
                end)

                it("should convert range when end_row is missing", function()
                    local diagnostic = {
                        row = 1,
                        col = 5,
                        end_row = nil,
                        end_col = 6,
                    }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 0)
                    assert.equals(diagnostic.col, 4)
                    assert.equals(diagnostic.end_col, 5)
                end)

                it("should convert range when end_col is missing", function()
                    local diagnostic = {
                        row = 1,
                        col = 5,
                        end_row = 2,
                        end_col = nil,
                    }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 1)
                    assert.equals(diagnostic.col, 4)
                    assert.equals(diagnostic.end_col, 0)
                end)

                it("should convert range when all positions are missing", function()
                    local diagnostic = {
                        row = nil,
                        col = nil,
                        end_row = nil,
                        end_col = nil,
                    }

                    postprocess(diagnostic, mock_params, mock_generator)

                    assert.equals(diagnostic.lnum, 0)
                    assert.equals(diagnostic.end_lnum, 1)
                    assert.equals(diagnostic.col, 0)
                    assert.equals(diagnostic.end_col, 0)
                end)
            end)

            it("should keep diagnostic source when defined", function()
                postprocess(mock_diagnostic, mock_params, { opts = {} })

                assert.equals(mock_diagnostic.source, "source")
            end)

            it("should set source from generator name", function()
                mock_diagnostic.source = nil

                postprocess(mock_diagnostic, mock_params, { opts = { name = "generator-source" } })

                assert.equals(mock_diagnostic.source, "generator-source")
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
    end)
end)
