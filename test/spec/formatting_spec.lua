local stub = require("luassert.stub")
local mock = require("luassert.mock")

local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")
local diff = require("null-ls.diff")

local method = methods.lsp.FORMATTING

local lsp = mock(vim.lsp, true)
mock(require("null-ls.logger"), true)

describe("formatting", function()
    stub(diff, "compute_diff")
    stub(generators, "run_registered_sequentially")
    stub(u, "make_params")
    stub(u.buf, "content")
    stub(vim.api, "nvim_create_buf")

    local handler = stub.new()

    local api
    local mock_uri = "file:///mock-file"
    local mock_bufnr, mock_client_id = vim.uri_to_bufnr(mock_uri), 999
    local mock_temp_bufnr = 555
    local mock_params
    before_each(function()
        api = mock(vim.api, true)

        mock_params = {
            textDocument = { uri = mock_uri },
            client_id = mock_client_id,
            bufnr = mock_bufnr,
            lsp_method = method,
        }

        diff.compute_diff.returns({})
        lsp.get_active_clients.returns({})
        u.make_params.returns({})
        api.nvim_create_buf.returns(mock_temp_bufnr)
        api.nvim_buf_is_loaded.returns(true)
    end)

    after_each(function()
        diff.compute_diff:clear()
        generators.run_registered_sequentially:clear()
        handler:clear()
        lsp.util.apply_text_edits:clear()
        u.buf.content:clear()
        u.make_params:clear()

        mock.revert(api)

        u.buf.content.returns(nil)
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
            assert.equals(type(opts.postprocess), "function")
            assert.equals(type(opts.after_each), "function")
            assert.equals(type(opts.callback), "function")
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

        it("should override params.content with temp buffer content", function()
            u.buf.content.returns("temp file content")
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local make_params = generators.run_registered_sequentially.calls[1].refs[1].make_params
            local updated_params = make_params()

            assert.stub(u.buf.content).was_called_with(mock_temp_bufnr)
            assert.equals(updated_params.content, "temp file content")
        end)
    end)

    describe("callback", function()
        it("should call handler with diffed edits", function()
            local mock_edits = { newText = "newText", rangeLength = 7 }
            diff.compute_diff.returns(mock_edits)

            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local callback = generators.run_registered_sequentially.calls[1].refs[1].callback
            callback()

            assert.stub(handler).was_called_with({ mock_edits })
        end)

        it("should call handler with empty response if diff is empty", function()
            local mock_edits = { newText = "", rangeLength = 0 }
            diff.compute_diff.returns(mock_edits)

            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local callback = generators.run_registered_sequentially.calls[1].refs[1].callback
            callback()

            assert.stub(handler).was_called_with(nil)
        end)
    end)
end)
