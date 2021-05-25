local stub = require("luassert.stub")

local diagnostics = require("null-ls.diagnostics")
local code_actions = require("null-ls.code-actions")
local formatting = require("null-ls.formatting")
local methods = require("null-ls.methods")

local lsp = vim.lsp

describe("handlers", function()
    local handlers = require("null-ls.handlers")

    describe("setup", function()
        it("should replace lsp handlers with overrides on setup", function()
            handlers.setup()

            assert.equals(lsp.buf_request, handlers.buf_request)
            assert.equals(lsp.buf_request_all, handlers.buf_request_all)
        end)
    end)

    describe("buf_request", function()
        stub(lsp, "buf_get_clients")
        local mock_handler = stub.new()
        local buf_request = stub.new()
        handlers.originals.buf_request = buf_request

        after_each(function()
            lsp.buf_get_clients:clear()
            mock_handler:clear()
            buf_request:clear()
        end)

        it("should call original buf_request method with arguments", function()
            handlers.buf_request(1, "mockMethod", {}, mock_handler)

            assert.stub(buf_request).was_called_with(1, "mockMethod", {},
                                                     mock_handler)
        end)

        it(
            "should pass original handler when method matches but skip flag is set",
            function()
                handlers.buf_request(1, methods.lsp.CODE_ACTION,
                                     {_null_ls_skip = true}, mock_handler)

                assert.equals(buf_request.calls[1].refs[4], mock_handler)
            end)

        it(
            "should pass wrapped handler when method matches and skip flag is not set",
            function()
                handlers.buf_request(1, methods.lsp.CODE_ACTION, {},
                                     mock_handler)

                assert.is_not.equals(buf_request.calls[1].refs[4], mock_handler)
            end)

        describe("wrapped handler", function()
            local mock_clients = {
                {resolved_capabilities = {code_action = true}},
                {resolved_capabilities = {code_action = true}}
            }

            local wrapped
            before_each(function()
                lsp.buf_get_clients.returns(mock_clients)

                handlers.buf_request(1, methods.lsp.CODE_ACTION, {},
                                     mock_handler)
                wrapped = buf_request.calls[1].refs[4]
            end)

            it("should call handler after completed > expected", function()
                wrapped()
                assert.stub(mock_handler).was_not_called()

                wrapped()
                assert.stub(mock_handler).was_called()
            end)
        end)
    end)

    describe("buf_request_all", function()
        local mock_callback = stub.new()
        local buf_request_all = stub.new()
        handlers.originals.buf_request_all = buf_request_all

        after_each(function()
            mock_callback:clear()
            buf_request_all:clear()
        end)

        it("should set flag on params and pass arguments to original method",
           function()
            handlers.buf_request_all(1, "mockMethod", {}, mock_callback)

            assert.stub(buf_request_all).was_called_with(1, "mockMethod", {
                _null_ls_skip = true
            }, mock_callback)
        end)
    end)

    describe("setup_client", function()
        stub(diagnostics, "handler")
        stub(code_actions, "handler")
        stub(formatting, "handler")
        local mock_request = stub.new()
        local mock_handler = stub.new()

        local mock_client
        before_each(function()
            mock_client = {request = mock_request}
            handlers.setup_client(mock_client)
        end)
        after_each(function()
            code_actions.handler:clear()
            diagnostics.handler:clear()
            formatting.handler:clear()
            mock_request:clear()
            mock_handler:clear()
        end)

        describe("notify", function()
            it("should call diagnostics handler with params", function()
                mock_client.notify(methods.lsp.DID_OPEN, {})

                assert.stub(diagnostics.handler).was_called_with(
                    {method = methods.lsp.DID_OPEN})
            end)

            it("should return true", function()
                local response = mock_client.notify("mockMethod", {})

                assert.equals(response, true)
            end)
        end)

        describe("request", function()
            it(
                "should return true and request_id if _null_ls_handled flag is set",
                function()
                    local response, request_id =
                        mock_client.request("mockMethod",
                                            {_null_ls_handled = true},
                                            mock_handler, 1)

                    assert.equals(response, true)
                    assert.equals(request_id, methods.internal._REQUEST_ID)
                end)

            it(
                "should call original request handler if handled flag is not set",
                function()
                    mock_request.returns(true)
                    local response = mock_client.request("mockMethod", {},
                                                         mock_handler, 1)

                    assert.stub(mock_request).was_called_with("mockMethod", {
                        method = "mockMethod"
                    }, mock_handler, 1)
                    assert.equals(response, true)
                end)

            it("should pass args to code actions handler", function()
                mock_client.request("mockMethod", {}, mock_handler, 1)

                assert.stub(code_actions.handler).was_called_with("mockMethod",
                                                                  {
                    method = "mockMethod"
                }, mock_handler, 1)
            end)

            it("should pass args to formatting handler", function()
                mock_client.request("mockMethod", {}, mock_handler, 1)

                assert.stub(formatting.handler).was_called_with("mockMethod", {
                    method = "mockMethod"
                }, mock_handler, 1)
            end)
        end)

        describe("cancel_request", function()
            it("should return true if request_id matches", function()
                local response = mock_client.cancel_request(
                                     methods.internal._REQUEST_ID)

                assert.equals(response, true)
            end)

            it("should return nil if request_id does not match", function()
                local response = mock_client.cancel_request(1111)

                assert.equals(response, nil)
            end)
        end)
    end)
end)
