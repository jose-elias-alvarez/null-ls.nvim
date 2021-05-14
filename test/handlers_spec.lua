local spy = require("luassert.spy")
local mock = require("luassert.mock")

local methods = require("null-ls.methods")
local code_actions = require("null-ls.code-actions")

local lsp = mock(vim.lsp, true)

describe("overrides", function()
    _G._TEST = true

    local handlers = require("null-ls.handlers")
    after_each(function()
        lsp.buf_request:clear()
        lsp.buf.execute_command:clear()
        lsp.util.apply_workspace_edit:clear()
        lsp.handlers[methods.DIAGNOSTICS]:clear()
    end)

    describe("buf_request", function()
        local mock_bufnr = 1
        local mock_params = {param = "something important"}
        local mock_handler = spy.new()

        it(
            "should call buf_request_original with code action handler when method matches",
            function()
                handlers.buf_request(mock_bufnr, methods.CODE_ACTION,
                                     mock_params, mock_handler)

                assert.stub(lsp.buf_request).was_called()
                local refs = lsp.buf_request.calls[1].refs
                assert.equals(refs[1], mock_bufnr)
                assert.equals(refs[2], methods.CODE_ACTION)
                assert.equals(refs[3], mock_params)
                assert.is_not.equals(refs[4], mock_handler)
            end)

        it(
            "should call buf_request_original with original handler when method does not match",
            function()
                local other_method = "otherMethod"
                handlers.buf_request(mock_bufnr, other_method, mock_params,
                                     mock_handler)

                assert.stub(lsp.buf_request).was_called()
                local refs = lsp.buf_request.calls[1].refs
                assert.equals(refs[1], mock_bufnr)
                assert.equals(refs[2], other_method)
                assert.equals(refs[3], mock_params)
                assert.equals(refs[4], mock_handler)
            end)
    end)

    describe("execute_command", function()
        it("should call cmd.action and return when command matches", function()
            local mock_command = {
                action = spy.new(function() end),
                command = code_actions.NULL_LS_CODE_ACTION
            }

            handlers.execute_command(mock_command)

            assert.spy(mock_command.action).was_called()
            assert.stub(lsp.buf.execute_command).was_not_called()
        end)

        it("should call execute_command_original when command does not match",
           function()
            local mock_command = {
                action = spy.new(function() end),
                command = "_someOtherCommand"
            }

            handlers.execute_command(mock_command)

            assert.spy(mock_command.action).was_not_called()
            assert.stub(lsp.buf.execute_command).was_called()
        end)
    end)

    describe("diagnostics", function()
        it("should call diagnostics handler with params and client id",
           function()
            local mock_params = {uri = "mock URI"}

            handlers.diagnostics(mock_params)

            assert.stub(lsp.handlers[methods.DIAGNOSTICS]).was_called_with(nil,
                                                                           nil,
                                                                           mock_params,
                                                                           handlers.NULL_LS_CLIENT_ID,
                                                                           nil,
                                                                           {})
        end)
    end)
end)
