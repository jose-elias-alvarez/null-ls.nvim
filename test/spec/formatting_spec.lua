local stub = require("luassert.stub")
local mock = require("luassert.mock")

local u = require("null-ls.utils")
local c = require("null-ls.config")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local method = methods.lsp.FORMATTING

local lsp = mock(vim.lsp, true)

describe("formatting", function()
    stub(vim, "cmd")
    stub(u, "make_params")
    stub(generators, "run")

    local handler = stub.new()

    local api
    local mock_uri = "file:///mock-file"
    local mock_bufnr, mock_client_id = vim.uri_to_bufnr(mock_uri), 999
    local mock_params
    before_each(function()
        api = mock(vim.api, true)

        c._set({ save_after_format = false })
        mock_params = { textDocument = { uri = mock_uri }, client_id = mock_client_id }
    end)

    after_each(function()
        mock.revert(api)
        lsp.util.apply_text_edits:clear()
        lsp.util.compute_diff:clear()
        vim.cmd:clear()

        u.make_params:clear()
        generators.run:clear()
        handler:clear()

        c.reset()
    end)

    local formatting = require("null-ls.formatting")

    describe("handler", function()
        it("should not set handled flag if method does not match", function()
            formatting.handler("otherMethod", mock_params, handler)

            assert.equals(mock_params._null_ls_handled, nil)
        end)

        it("should set handled flag if method matches", function()
            formatting.handler(method, mock_params, handler)

            assert.equals(mock_params._null_ls_handled, true)
        end)

        it("should assign bufnr to params", function()
            formatting.handler(method, mock_params, handler)

            assert.equals(mock_params.bufnr, mock_bufnr)
        end)
    end)

    describe("apply_edits", function()
        stub(s, "get")

        local mock_client_id = 99
        local mock_edits = { { text = "new text" } }
        local mock_diffed = {
            text = "diffed text",
            range = {
                start = { line = 0, character = 10 },
                ["end"] = { line = 35, character = 1 },
            },
        }
        before_each(function()
            s.get.returns({ client_id = mock_client_id })
            lsp.util.compute_diff.returns(mock_diffed)
        end)
        after_each(function()
            s.get:clear()
        end)

        it("should call make_params with params and internal method", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            assert.same(u.make_params.calls[1].refs[1], mock_params)
            assert.equals(u.make_params.calls[1].refs[2], methods.internal.FORMATTING)
        end)

        it("should call handler with text edits", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local callback = generators.run.calls[1].refs[3]
            callback(mock_edits, mock_params)

            assert.stub(handler).was_called_with({ { newText = mock_diffed.text, range = mock_diffed.range } })
        end)

        it("should not save buffer if config option is not set", function()
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local callback = generators.run.calls[1].refs[3]
            callback(mock_edits, mock_params)

            assert.stub(vim.cmd).was_not_called_with(mock_bufnr .. "bufdo! silent keepjumps noautocmd update")
        end)

        it("should save buffer if config option is set", function()
            c.setup({ save_after_format = true })
            formatting.handler(methods.lsp.FORMATTING, mock_params, handler)

            local callback = generators.run.calls[1].refs[3]
            callback(mock_edits, mock_params)
            vim.wait(100)

            assert.stub(vim.cmd).was_called_with(mock_bufnr .. "bufdo! silent keepjumps noautocmd update")
        end)
    end)
end)
