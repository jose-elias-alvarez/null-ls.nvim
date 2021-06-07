local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local c = require("null-ls.config")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local method = methods.lsp.FORMATTING

describe("formatting", function()
    stub(vim.lsp.util, "apply_text_edits")
    stub(vim.api, "nvim_win_get_buf")
    stub(vim.api, "nvim_win_set_buf")
    stub(vim, "cmd")
    stub(a, "await")

    stub(u, "make_params")
    stub(generators, "run")
    local handler = stub.new()

    local mock_bufnr = 65
    local mock_params
    before_each(function()
        c._set({ save_after_format = false })
        mock_params = { key = "val" }
    end)

    after_each(function()
        vim.lsp.util.apply_text_edits:clear()
        vim.api.nvim_win_get_buf:clear()
        vim.api.nvim_win_set_buf:clear()
        vim.cmd:clear()
        a.await:clear()

        u.make_params:clear()
        generators.run:clear()
        handler:clear()

        c.reset()
    end)

    local formatting = require("null-ls.formatting")

    describe("handler", function()
        it("should not set handled flag if method does not match", function()
            formatting.handler("otherMethod", mock_params, handler, mock_bufnr)

            assert.equals(mock_params._null_ls_handled, nil)
        end)

        it("should set handled flag if method matches", function()
            formatting.handler(method, mock_params, handler, mock_bufnr)

            assert.equals(mock_params._null_ls_handled, true)
        end)

        it("should assign bufnr to params", function()
            formatting.handler(method, mock_params, handler, mock_bufnr)

            assert.equals(mock_params.bufnr, mock_bufnr)
        end)
    end)

    describe("apply_edits", function()
        stub(s, "get")

        local mock_client_id = 99
        before_each(function()
            s.get.returns({ client_id = mock_client_id })
        end)
        after_each(function()
            s.get:clear()
        end)

        it("should call make_params with params and internal method", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.same(u.make_params.calls[1].refs[1], mock_params)
            assert.equals(u.make_params.calls[1].refs[2], methods.internal.FORMATTING)
        end)

        it("should call handler with empty response", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.stub(handler).was_called_with(nil, methods.lsp.FORMATTING, {}, mock_client_id, mock_bufnr)
        end)

        it("should call apply_text_edits with edits", function()
            a.await.returns("edits")

            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.stub(vim.lsp.util.apply_text_edits).was_called_with("edits", mock_bufnr)
        end)

        it("should not save buffer if config option is not set", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.stub(vim.cmd).was_not_called()
        end)

        it("should save buffer if config option is set", function()
            c.setup({ save_after_format = true })

            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.stub(vim.cmd).was_called_with(mock_bufnr .. "bufdo! silent noautocmd update")
        end)

        it("should set window buffer to original buffer if it doesn't match", function()
            local current_bufnr = mock_bufnr + 1
            vim.api.nvim_win_get_buf.returns(current_bufnr)
            c.setup({ save_after_format = true })

            formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)

            assert.stub(vim.api.nvim_win_set_buf).was_called_with(0, current_bufnr)
        end)

        describe("postprocess", function()
            local edit = { row = 1, col = 5, text = "something bad" }
            local postprocess
            before_each(function()
                formatting.handler(methods.lsp.FORMATTING, mock_params, handler, mock_bufnr)
                postprocess = generators.run.calls[1].refs[2]
            end)

            it("should convert range", function()
                postprocess(edit)

                assert.same(edit.range.start, { character = 5, line = 1 })
                assert.same(edit.range["end"], { character = -1, line = 1 })
            end)

            it("should assign edit newText", function()
                postprocess(edit)

                assert.equals(edit.newText, edit.text)
            end)
        end)
    end)
end)
