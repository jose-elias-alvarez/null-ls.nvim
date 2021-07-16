local methods = require("null-ls.methods")
local code_actions = require("null-ls.code-actions")
local formatting = require("null-ls.formatting")
local diagnostics = require("null-ls.diagnostics")

local rpc = require("vim.lsp.rpc")

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

function M.setup()
    local rpc_start = rpc.start
    rpc.start = function(cmd, ...)
        if cmd == "nvim" then
            return M.start()
        end
        return rpc_start(cmd, ...)
    end
end

local function get_client(pid)
    for _, client in pairs(vim.lsp.get_active_clients()) do
        if client.rpc.pid == pid then
            return client
        end
    end
end

function M.start()
    lastpid = lastpid + 1
    local message_id = 1
    local pid = lastpid
    local stopped = false

    local client
    local function handle(method, params, callback)
        callback = callback and vim.schedule_wrap(callback)
        message_id = message_id + 1
        local is_notify = callback == nil
        client = client or get_client(pid)

        params.method = method
        if client then
            params.client_id = client.id
        end

        local send = function(result)
            if callback then
                callback(nil, result or vim.NIL)
            end
        end

        if method == methods.lsp.INITIALIZE then
            send({ capabilities = capabilities })
        elseif method == methods.lsp.SHUTDOWN then
            stopped = true
            send()
        else
            if is_notify then
                diagnostics.handler(params)
            end
            code_actions.handler(method, params, send)
            formatting.handler(method, params, send)
            if not params._null_ls_handled then
                send()
            end
        end

        return true, message_id
    end

    local function request(method, params, callback)
        return handle(method, params, callback)
    end

    local function notify(method, params)
        return handle(method, params)
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

return M
