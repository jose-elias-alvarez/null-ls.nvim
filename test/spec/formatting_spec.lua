local stub = require("luassert.stub")
local mock = require("luassert.mock")

local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local method = methods.lsp.FORMATTING

local lsp = mock(vim.lsp, true)

describe("formatting", function()
    stub(vim, "cmd")
    stub(u, "make_params")
    stub(generators, "run_registered_sequentially")

    local handler = stub.new()

    local api
    local mock_uri = "file:///mock-file"
    local mock_bufnr, mock_client_id = vim.uri_to_bufnr(mock_uri), 999
    local mock_params
    before_each(function()
        api = mock(vim.api, true)
        mock_params = {
            textDocument = { uri = mock_uri },
            client_id = mock_client_id,
            bufnr = mock_bufnr,
            lsp_method = method,
        }
        lsp.get_active_clients.returns({})
    end)

    after_each(function()
        mock.revert(api)
        lsp.util.apply_text_edits:clear()
        lsp.util.compute_diff:clear()
        vim.cmd:clear()
        u.make_params:clear()
        generators.run_registered_sequentially:clear()
        handler:clear()
    end)

    local formatting = require("null-ls.formatting")

    describe("handler", function()
        it("should not set handled flag if method does not match", function()
            formatting.handler("otherMethod", mock_params, handler)

            assert.equals(mock_params._null_ls_handled, nil)
        end)

        it("should set handled flag if method is lsp.FORMATTING", function()
            formatting.handler(method, mock_params, handler)

            assert.equals(mock_params._null_ls_handled, true)
        end)

        it("should set handled flag if method is lsp.RANGE_FORMATTING", function()
            formatting.handler(methods.lsp.RANGE_FORMATTING, mock_params, handler)

            assert.equals(mock_params._null_ls_handled, true)
        end)

        it("should call run_registered_sequentially with opts", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local opts = generators.run_registered_sequentially.calls[1].refs[1]

            assert.equals(opts.filetype, vim.api.nvim_buf_get_option(mock_params.bufnr, "filetype"))
            assert.equals(opts.method, methods.map[method])
            assert.equals(type(opts.make_params), "function")
            assert.equals(type(opts.callback), "function")
            assert.equals(type(opts.after_all), "function")
        end)
    end)

    describe("make_params", function()
        it("should call make_params with params and internal method", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local make_params = generators.run_registered_sequentially.calls[1].refs[1].make_params
            make_params()

            assert.same(u.make_params.calls[1].refs[1], mock_params)
            assert.equals(u.make_params.calls[1].refs[2], methods.internal.FORMATTING)
        end)
    end)

    describe("callback", function()
        local mock_edits = { { text = "new text" } }
        local mock_diffed = {
            text = "diffed text",
            range = {
                start = { line = 0, character = 10 },
                ["end"] = { line = 35, character = 1 },
            },
        }

        local lsp_handler = stub.new()
        local original_handler = vim.lsp.handlers[method]
        before_each(function()
            vim.lsp.handlers[method] = lsp_handler
            lsp.util.compute_diff.returns(mock_diffed)
        end)
        after_each(function()
            lsp_handler:clear()
            vim.lsp.handlers[method] = original_handler
        end)

        describe("handler", function()
            local has = stub(vim.fn, "has")
            after_each(function()
                has:clear()
            end)

            describe("0.5", function()
                before_each(function()
                    has.returns(0)
                end)

                it("should call lsp_handler with text edit response", function()
                    formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

                    local callback = generators.run_registered_sequentially.calls[1].refs[1].callback
                    callback(mock_edits, mock_params)

                    assert.stub(lsp_handler).was_called_with(
                        nil,
                        mock_params.lsp_method,
                        { { newText = mock_diffed.text, range = mock_diffed.range } },
                        mock_params.client_id,
                        mock_params.bufnr
                    )
                end)
            end)

            describe("0.5.1", function()
                before_each(function()
                    has.returns(1)
                end)

                it("should call lsp_handler with text edit response", function()
                    formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

                    local callback = generators.run_registered_sequentially.calls[1].refs[1].callback
                    callback(mock_edits, mock_params)

                    assert.stub(lsp_handler).was_called_with(
                        nil,
                        { { newText = mock_diffed.text, range = mock_diffed.range } },
                        {
                            method = mock_params.lsp_method,
                            client_id = mock_params.client_id,
                            bufnr = mock_params.bufnr,
                        }
                    )
                end)
            end)
        end)
    end)

    describe("after_all", function()
        it("should call original handler with empty response", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local after_all = generators.run_registered_sequentially.calls[1].refs[1].after_all
            after_all()

            assert.stub(handler).was_called_with(nil, method, nil, mock_params.client_id, mock_params.bufnr)
        end)
    end)
end)
