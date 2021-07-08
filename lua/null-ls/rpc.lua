local methods = require("null-ls.methods")

local rpc = require("vim.lsp.rpc")
local rpc_start = rpc.start

local M = {}

local capabilities = {
    codeActionProvider = true,
    executeCommandProvider = true,
    documentFormattingProvider = true,
    documentRangeFormattingProvider = true,
    textDocumentSync = {
        change = 1, -- prompt LSP client to send full document text on didOpen and didChange
        openClose = true,
    },
}

local lastpid = 5000

rpc.start = function(cmd, ...)
    if cmd == "nvim" then
        return M.start(cmd, ...)
    end
    return rpc_start(cmd, ...)
end

function M.start(...)
    lastpid = lastpid + 1
    local pid = lastpid
    local stopped = false

    local function handle(method, _params, callback)
        local send_response = function(result)
            if callback then
                callback(nil, result)
            end
        end

        local send_nil_response = function()
            send_response(vim.NIL)
        end
        if method == methods.lsp.INITIALIZE then
            send_response({ capabilities = capabilities })
        end
        if method == methods.lsp.SHUTDOWN then
            send_nil_response()
        end
        if method == methods.lsp.EXECUTE_COMMAND then
            stopped = true
            send_nil_response()
        end
        if method == methods.lsp.CODE_ACTION then
            send_nil_response()
        end
        if method == methods.lsp.DID_CHANGE then
            send_nil_response()
        end
    end

    local function request(method, params, callback)
        print("request: " .. method)
        handle(method, params, callback)
    end

    local function notify(method, params)
        print("notify: " .. method)
        handle(method, params)
    end

    return {
        request = request,
        notify = notify,
        pid = pid,
        handle = {
            is_closing = function()
                return stopped
            end,
            kill = function()
                stopped = true
            end,
        },
    }
end
