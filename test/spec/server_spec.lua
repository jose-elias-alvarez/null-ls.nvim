local stub = require("luassert.stub")
local match = require("luassert.match")

local methods = require("null-ls.methods")

local json = {decode = vim.fn.json_decode, encode = vim.fn.json_encode}

describe("server", function()
    stub(vim.fn, "stdioopen")
    stub(vim.fn, "chansend")
    stub(vim, "cmd")
    stub(vim.lsp.rpc, "rpc_response_error")

    after_each(function()
        vim.fn.stdioopen:clear()
        vim.fn.chansend:clear()
        vim.cmd:clear()
        vim.lsp.rpc.rpc_response_error:clear()
    end)

    local server = require("null-ls.server")

    describe("start", function()
        it("should call stdioopen with on_stdin callback", function()
            server.start()

            assert.stub(vim.fn.stdioopen).was_called()
            assert.truthy(vim.fn.stdioopen.calls[1].refs[1].on_stdin)
        end)
    end)

    describe("on_stdin", function()
        local chan_id, lsp_id = 1, 2

        local on_stdin
        before_each(function()
            server.start()
            on_stdin = vim.fn.stdioopen.calls[1].refs[1].on_stdin
        end)

        local send_mock_data = function(data)
            local encoded = {
                {"Content-Length: any"}, {"\r\n\r\n"}, json.encode(data)
            }
            on_stdin(chan_id, encoded)
        end

        it("should send error when json decoding fails", function()
            vim.lsp.rpc.rpc_response_error.returns(
                {err = "something went wrong"})

            on_stdin(chan_id, {"not json"})

            assert.stub(vim.lsp.rpc.rpc_response_error).was_called_with(-32700)
            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match(
                                                             "something went wrong"))
        end)

        it("should send lsp_id with response", function()
            send_mock_data({id = lsp_id, method = methods.lsp.INITIALIZE})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match(
                                                             tostring(lsp_id)))
        end)

        it("should send capabilities if method == INITIALIZE", function()
            send_mock_data({id = lsp_id, method = methods.lsp.INITIALIZE})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match(
                                                             "capabilities"))
        end)

        it("should send nil response and exit if method == SHUTDOWN", function()
            send_mock_data({id = lsp_id, method = methods.lsp.SHUTDOWN})

            assert.stub(vim.cmd).was_called_with("noa qa!")
            assert.stub(vim.fn.chansend).was_called()
        end)

        it("should send nil response if method == EXECUTE_COMMAND", function()
            send_mock_data({id = lsp_id, method = methods.lsp.EXECUTE_COMMAND})

            assert.stub(vim.fn.chansend).was_called()
        end)

        it("should send nil response if method == CODE_ACTION", function()
            send_mock_data({id = lsp_id, method = methods.lsp.CODE_ACTION})

            assert.stub(vim.fn.chansend).was_called()
        end)

        it("should send nil response if method == DID_CHANGE", function()
            send_mock_data({id = lsp_id, method = methods.lsp.DID_CHANGE})

            assert.stub(vim.fn.chansend).was_called()
        end)
    end)
end)
