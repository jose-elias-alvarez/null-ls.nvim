local methods = require("null-ls.methods")
local u = require("null-ls.utils")

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
    local rpc = require("vim.lsp.rpc")

    local rpc_start = rpc.start
    rpc.start = function(cmd, cmd_args, dispatchers, ...)
        local config = require("lspconfig")["null-ls"]
        if config and cmd == config.cmd[1] then
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

        if type(params) ~= "table" then
            params = { params }
        end

        params.method = method
        if client then
            params.client_id = client.id
            require("null-ls.handlers").setup_client(client)
        end

        local send = function(result)
            if callback then
                callback(nil, result)
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
                require("null-ls.diagnostics").handler(params)
            end
            require("null-ls.code-actions").handler(method, params, send)
            require("null-ls.formatting").handler(method, params, send)
            require("null-ls.hover").handler(method, params, send)
            if not params._null_ls_handled then
                send()
            end
        end

        return true, message_id
    end

    local function request(method, params, callback)
        u.debug_log("received LSP request for method " .. method)
        return handle(method, params, callback)
    end

    local function notify(method, params)
        u.debug_log("received LSP notification for method " .. method)
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
