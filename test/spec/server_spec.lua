local stub = require("luassert.stub")
local match = require("luassert.match")

local loop = require("null-ls.loop")
local methods = require("null-ls.methods")

local json = {decode = vim.fn.json_decode, encode = vim.fn.json_encode}

describe("server", function()
    stub(vim.fn, "stdioopen")
    stub(vim.fn, "chansend")
    stub(vim, "cmd")
    stub(loop, "timer")

    local stop, restart = stub.new(), stub.new()
    before_each(function()
        loop.timer.returns({stop = stop, restart = restart})
    end)
    after_each(function()
        vim.fn.stdioopen:clear()
        vim.fn.chansend:clear()
        vim.cmd:clear()
        loop.timer:clear()
        stop:clear()
    end)

    local server = require("null-ls.server")

    describe("start", function()
        it("should call stdioopen with on_stdin callback", function()
            server.start()

            assert.stub(vim.fn.stdioopen).was_called()
            assert.truthy(vim.fn.stdioopen.calls[1].refs[1].on_stdin)
        end)

        it("should create timer with correct args and callback", function()
            server.start()

            assert.equals(loop.timer.calls[1].refs[1], 30000)
            assert.equals(loop.timer.calls[1].refs[2], nil)
            assert.equals(loop.timer.calls[1].refs[3], true)
            assert.truthy(loop.timer.calls[1].refs[4])
        end)

        it("should call shutdown on timer callback", function()
            server.start()

            local callback = loop.timer.calls[1].refs[4]
            callback()

            assert.stub(stop).was_called()
            assert.stub(vim.cmd).was_called_with("noautocmd qa!")
        end)
    end)

    describe("on_stdin", function()
        local chan_id, id = 1, 1

        local on_stdin
        before_each(function()
            id = id + 1
            server.start()
            on_stdin = vim.fn.stdioopen.calls[1].refs[1].on_stdin
        end)

        local send_mock_data = function(data)
            local encoded = {
                {"Content-Length: any"}, {"\r\n\r\n"}, json.encode(data)
            }
            on_stdin(chan_id, encoded)
        end

        it("should send id with response", function()
            send_mock_data({id = id, method = methods.lsp.INITIALIZE})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match(
                                                             tostring(id)))
        end)

        it("should send capabilities if method == INITIALIZE", function()
            send_mock_data({id = id, method = methods.lsp.INITIALIZE})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match(
                                                             "capabilities"))
        end)

        it("should restart timer with timeout if method == NOTIFICATION",
           function()
            send_mock_data({
                id = id,
                method = methods.internal._NOTIFICATION,
                params = {timeout = 500}
            })

            assert.stub(restart).was_called_with(1000)
        end)

        it("should send nil response and shut down if method == SHUTDOWN",
           function()
            send_mock_data({id = id, method = methods.lsp.SHUTDOWN})

            assert.stub(vim.cmd).was_called_with("noautocmd qa!")
            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match("null"))
        end)

        it("should send nil response if method == EXECUTE_COMMAND", function()
            send_mock_data({id = id, method = methods.lsp.EXECUTE_COMMAND})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match("null"))
        end)

        it("should send nil response if method == CODE_ACTION", function()
            send_mock_data({id = id, method = methods.lsp.CODE_ACTION})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match("null"))
        end)

        it("should send nil response if method == DID_CHANGE", function()
            send_mock_data({id = id, method = methods.lsp.DID_CHANGE})

            assert.stub(vim.fn.chansend).was_called_with(chan_id,
                                                         match.has_match("null"))
        end)
    end)
end)
