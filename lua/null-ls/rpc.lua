local c = require("null-ls.config")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")

local pid = 5000
local notification_cache = {}

local should_cache = function(method)
    return not c.get().update_in_insert and method == methods.lsp.DID_CHANGE and vim.api.nvim_get_mode().mode:find("i")
end

local set_cache = function(params)
    local uri = params.textDocument and params.textDocument.uri
    if uri then
        notification_cache[uri] = params
    end
end

local clear_cache = function(params)
    local uri = params.textDocument and params.textDocument.uri
    if uri and notification_cache[uri] then
        notification_cache[uri] = nil
    end
end

local M = {}

local capabilities = {
    codeActionProvider = {
        -- TODO: investigate if we can use this
        resolveProvider = false,
    },
    executeCommandProvider = true,
    documentFormattingProvider = true,
    documentRangeFormattingProvider = true,
    completionProvider = {
        -- FIXME: How do we decide what trigger characters are?
        triggerCharacters = { ".", ":", "-" },
        allCommitCharacters = {},
        resolveProvider = false,
        completionItem = {
            labelDetailsSupport = true,
        },
    },
    textDocumentSync = {
        change = 1, -- prompt LSP client to send full document text on didOpen and didChange
        openClose = true,
        save = { includeText = true },
    },
    hoverProvider = true,
}

M.capabilities = capabilities

M.setup = function()
    local rpc = require("vim.lsp.rpc")
    if rpc._null_ls_setup then
        return
    end

    local rpc_start = rpc.start
    rpc.start = function(cmd, cmd_args, dispatchers, ...)
        if cmd == c.get().cmd[1] then
            return M.start(dispatchers)
        end
        return rpc_start(cmd, cmd_args, dispatchers, ...)
    end

    rpc._null_ls_setup = true
end

M.start = function(dispatchers)
    pid = pid + 1
    local message_id = 1
    local stopped = false

    local function handle(method, params, callback, is_notify)
        params = params or {}
        callback = callback and vim.schedule_wrap(callback)
        message_id = message_id + 1

        if type(params) ~= "table" then
            params = { params }
        end

        params.method = method
        params.client_id = require("null-ls.client").get_id()

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
            require("null-ls.completion").handler(method, params, send)
            if not params._null_ls_handled then
                send()
            end
        end

        return true, message_id
    end

    local function request(method, params, callback, notify_callback)
        log:trace("received LSP request for method " .. method)

        -- clear pending requests from client object
        local success = handle(method, params, callback)
        if success and notify_callback then
            -- copy before scheduling to make sure it hasn't changed
            local id_to_clear = message_id
            vim.schedule(function()
                notify_callback(id_to_clear)
            end)
        end

        return success, message_id
    end

    local function notify(method, params)
        if should_cache(method) then
            set_cache(params)
            return
        end

        if method == methods.lsp.DID_CLOSE then
            clear_cache(params)
        end

        log:trace("received LSP notification for method " .. method)
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

M.flush = function()
    for uri, notification in pairs(notification_cache) do
        require("null-ls.client").notify_client(methods.lsp.DID_CHANGE, notification)
        notification_cache[uri] = nil
    end
end

return M
