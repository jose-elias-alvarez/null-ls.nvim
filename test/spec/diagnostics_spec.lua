local mock = require("luassert.mock")
local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local lsp = mock(vim.lsp, "true")

describe("diagnostics", function()
    local diagnostics = require("null-ls.diagnostics")

    describe("handler", function()
        stub(vim, "uri_to_bufnr")
        stub(vim.fn, "buflisted")
        stub(a, "await")
        stub(u, "make_params")
        stub(sources, "run_generators")

        local mock_bufnr, mock_client_id = 99, 999
        local mock_params
        before_each(function()
            s.set_client_id(mock_client_id)
            mock_params = {textDocument = {uri = "file:///mock-file"}}
        end)

        after_each(function()
            vim.uri_to_bufnr:clear()
            vim.fn.buflisted:clear()
            lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS]:clear()
            a.await:clear()
            sources.run_generators:clear()
            u.make_params:clear()

            s.reset()
        end)

        it("should return immediately if params don't contain uri", function()
            diagnostics.handler({})

            assert.stub(vim.uri_to_bufnr).was_not_called()
        end)

        it("should return if buffer is not listed", function()
            vim.fn.buflisted.returns(0)

            diagnostics.handler(mock_params)

            assert.stub(vim.uri_to_bufnr).was_called_with(
                mock_params.textDocument.uri)
            assert.stub(u.make_params).was_not_called()
        end)

        it("should call make_params with params and method", function()
            vim.fn.buflisted.returns(1)
            vim.uri_to_bufnr.returns(mock_bufnr)
            u.make_params.returns({})

            diagnostics.handler(mock_params)

            assert.stub(u.make_params).was_called_with(
                {bufnr = mock_bufnr, textDocument = mock_params.textDocument},
                methods.internal.DIAGNOSTICS)
        end)

        it("should send results of diagnostic generators to lsp handler",
           function()
            vim.fn.buflisted.returns(1)
            vim.uri_to_bufnr.returns(mock_bufnr)
            u.make_params.returns({uri = mock_params.textDocument.uri})
            a.await.returns("diagnostics")

            diagnostics.handler(mock_params)

            assert.stub(lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS])
                .was_called_with(nil, nil, {
                diagnostics = "diagnostics",
                uri = mock_params.textDocument.uri
            }, mock_client_id, nil, {})
        end)

        describe("postprocess", function()
            local postprocess
            before_each(function()
                vim.fn.buflisted.returns(1)
                vim.uri_to_bufnr.returns(mock_bufnr)
                u.make_params.returns({uri = mock_params.textDocument.uri})

                diagnostics.handler(mock_params)
                postprocess = sources.run_generators.calls[1].refs[2]
            end)

            it("should convert range when all positions are defined", function()
                local diagnostic = {row = 1, col = 5, end_row = 2, end_col = 6}

                postprocess(diagnostic)

                assert.same(diagnostic.range, {
                    ["end"] = {character = 6, line = 1},
                    start = {character = 5, line = 0}
                })
            end)

            it("should convert range when row is missing", function()
                local diagnostic = {
                    row = nil,
                    col = 5,
                    end_row = 2,
                    end_col = 6
                }

                postprocess(diagnostic)

                assert.same(diagnostic.range, {
                    ["end"] = {character = 6, line = 1},
                    start = {character = 5, line = 0}
                })
            end)

            it("should convert range when col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = nil,
                    end_row = 2,
                    end_col = 6
                }

                postprocess(diagnostic)

                assert.same(diagnostic.range, {
                    ["end"] = {character = 6, line = 1},
                    start = {character = 0, line = 0}
                })
            end)

            it("should convert range when end_row is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = nil,
                    end_col = 6
                }

                postprocess(diagnostic)

                assert.same(diagnostic.range, {
                    ["end"] = {character = 6, line = 0},
                    start = {character = 5, line = 0}
                })
            end)

            it("should convert range when end_col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = 2,
                    end_col = nil
                }

                postprocess(diagnostic)

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

                postprocess(diagnostic)

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

                postprocess(diagnostic)

                assert.equals(diagnostic.source, "mock-source")
            end)

            it("should set default source when undefined", function()
                local diagnostic = {row = 1, col = 5, end_row = 2, end_col = 6}

                postprocess(diagnostic)

                assert.equals(diagnostic.source, "null-ls")
            end)
        end)
    end)
end)
