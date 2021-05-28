local loop = require("null-ls.loop")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local fn = vim.fn

local capabilities = {
    codeActionProvider = true,
    executeCommandProvider = true,
    documentFormattingProvider = true,
    textDocumentSync = {
        change = 1, -- prompt LSP client to send full document text on didOpen and didChange
        openClose = true
    }
}

local default_shutdown_timeout = 30000 -- 30 seconds

local M = {}
M.capabilities = capabilities

M.start = function()
    -- start timer to shutdown server after inactivity
    local timer
    local shutdown = function()
        if timer then timer.stop(true) end
        vim.cmd("noautocmd qa!")
    end
    timer = loop.timer(default_shutdown_timeout, nil, true, shutdown)

    local on_stdin = function(chan_id, encoded)
        local decoded = u.rpc.decode(encoded)
        if not decoded then
            -- TODO: figure out error handling
            return
        end

        local method, id, params = decoded.method, decoded.id, decoded.params
        local send_response = function(response)
            response.id = id
            fn.chansend(chan_id, u.rpc.format(response))
        end

        local send_nil_response = function()
            send_response({result = vim.NIL})
        end

        if method == methods.lsp.INITIALIZE then
            send_response({result = {capabilities = capabilities}})
        end

        if method == methods.internal._NOTIFICATION then
            -- restart timer on notification, slightly lengthened to account for gap
            timer.restart(params.timeout + 500)
        end

        if method == methods.lsp.SHUTDOWN then
            send_nil_response()
            shutdown()
        end

        if method == methods.lsp.EXECUTE_COMMAND then send_nil_response() end
        if method == methods.lsp.CODE_ACTION then send_nil_response() end
        if method == methods.lsp.DID_CHANGE then send_nil_response() end
    end

    fn.stdioopen({on_stdin = on_stdin})
end

return M
