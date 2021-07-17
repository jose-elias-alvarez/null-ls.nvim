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
    rpc.start = function(cmd, cmd_args, dispatchers, ...)
        if cmd == "nvim" then
            return M.start(dispatchers)
        end
        return rpc_start(cmd, cmd_args, dispatchers, ...)
    end
end

local function get_client(pid)
    for _, client in pairs(vim.lsp.get_active_clients()) do
        if client.rpc.pid == pid then
            return client
        end
    end
end

function M.start(dispatchers)
    lastpid = lastpid + 1
    local message_id = 1
    local pid = lastpid
    local stopped = false

    local client
    local function handle(method, params, callback, is_notify)
        params = params or {}
        callback = callback and vim.schedule_wrap(callback)
        message_id = message_id + 1
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
        elseif method == methods.lsp.EXIT then
            if dispatchers.on_exit then
                dispatchers.on_exit(0, 0)
            end
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
        return handle(method, params, nil, true)
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
