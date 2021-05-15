local stub = require("luassert.stub")

local s = require("null-ls.state")
local methods = require("null-ls.methods")

local lsp = vim.lsp

describe("overrides", function()
    stub(lsp.handlers, methods.DIAGNOSTICS)
    stub(s, "get")

    after_each(function()
        lsp.handlers[methods.DIAGNOSTICS]:clear()

        s.get:clear()
        -- lsp.buf_request:clear()
        -- lsp.buf.execute_command:clear()
        -- lsp.util.apply_workspace_edit:clear()
    end)

    local handlers = require("null-ls.handlers")
    -- describe("buf_request", function()
    --     local mock_bufnr = 1
    --     local mock_params = {param = "something important"}
    --     local mock_handler = stub.new()

    --     -- it(
    --     --     "should call buf_request_original with code action handler when method matches",
    --     --     function()
    --     --         handlers.buf_request(mock_bufnr, methods.CODE_ACTION,
    --     --                              mock_params, mock_handler)

    --     --         assert.stub(lsp.buf_request).was_called()
    --     --         local refs = lsp.buf_request.calls[1].refs
    --     --         assert.equals(refs[1], mock_bufnr)
    --     --         assert.equals(refs[2], methods.CODE_ACTION)
    --     --         assert.equals(refs[3], mock_params)
    --     --         assert.is_not.equals(refs[4], mock_handler)
    --     --     end)

    --     -- it(
    --     --     "should call buf_request_original with original handler when method does not match",
    --     --     function()
    --     --         local other_method = "otherMethod"
    --     --         handlers.buf_request(mock_bufnr, other_method, mock_params,
    --     --                              mock_handler)

    --     --         assert.stub(lsp.buf_request).was_called()
    --     --         local refs = lsp.buf_request.calls[1].refs
    --     --         assert.equals(refs[1], mock_bufnr)
    --     --         assert.equals(refs[2], other_method)
    --     --         assert.equals(refs[3], mock_params)
    --     --         assert.equals(refs[4], mock_handler)
    --     --     end)
    -- end)

    describe("diagnostics", function()
        it("should call diagnostics handler with params and state client id",
           function()
            local mock_params = {uri = "mock URI"}
            local mock_id = 5
            s.get.returns({client_id = mock_id})

            handlers.diagnostics(mock_params)

            assert.stub(lsp.handlers[methods.DIAGNOSTICS]).was_called_with(nil,
                                                                           nil,
                                                                           mock_params,
                                                                           mock_id,
                                                                           nil,
                                                                           {})
        end)
    end)
end)
