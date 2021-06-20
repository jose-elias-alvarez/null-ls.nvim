local methods = require("null-ls.methods")
local code_actions = require("null-ls.code-actions")
local formatting = require("null-ls.formatting")
local diagnostics = require("null-ls.diagnostics")

local lsp = vim.lsp
local api = vim.api
local handlers = lsp.handlers

local originals = {
    buf_request = lsp.buf_request,
    buf_request_all = lsp.buf_request_all,
}

local has_capability = function(client, method)
    return client.resolved_capabilities[lsp._request_name_to_capability[method]]
end

local get_expected_client_count = function(bufnr, method)
    local expected = 0
    local clients = lsp.buf_get_clients(bufnr)
    if not clients then
        return expected
    end

    for _, client in pairs(clients) do
        if has_capability(client, method) then
            expected = expected + 1
        end
    end
    return expected
end

-- many code action implementations (including the vim.lsp.buf.code_action)
-- use buf_request + a handler callback, which will be called once for each server
-- that returns code action results
--
-- we use a wrapper to combine results from all servers
-- and only call the handler once we have the expected number (much like buf_request_all)
local handle_all_factory = function(handler, method, bufnr)
    local expected = get_expected_client_count(bufnr, method)
    local completed = 0

    local all_results = {}
    return function(err, _, results, client_id)
        if err then
            handler(err, method, bufnr)
            return
        end

        vim.list_extend(all_results, results or {})
        completed = completed + 1

        if completed >= expected then
            handler(nil, nil, all_results, client_id, bufnr)
        end
    end
end

local should_wrap = function(method, params)
    return method == methods.lsp.CODE_ACTION and not params._null_ls_skip
end

local M = {}
M.originals = originals

M.setup = function()
    lsp.buf_request = M.buf_request
    lsp.buf_request_all = M.buf_request_all
end

M.reset = function()
    lsp.buf_request = originals.buf_request
    lsp.buf_request_all = originals.buf_request_all
end

M.buf_request = function(bufnr, method, params, original_handler)
    original_handler = original_handler or handlers[method]
    local handler = original_handler

    if should_wrap(method, params) then
        handler = handle_all_factory(original_handler, method, bufnr)
    end

    return originals.buf_request(bufnr, method, params, handler)
end

-- buf_request_all already wraps its handler,
-- so we set a flag to make sure we skip it
M.buf_request_all = function(bufnr, method, params, callback)
    params = params or {}
    params._null_ls_skip = true

    return originals.buf_request_all(bufnr, method, params, callback)
end

M.setup_client = function(client)
    local original_request, original_notify = client.request, client.notify

    client.notify = function(method, params)
        params = params or {}

        if method == methods.internal._NOTIFICATION then
            original_notify(method, params)
            return true
        end

        params.method = method
        diagnostics.handler(params)

        -- no need to actually send notifications to server,
        -- but we return true to indicate that the notification was received
        return true
    end

    client.request = function(method, params, handler, bufnr)
        bufnr = bufnr or api.nvim_get_current_buf()
        handler = handler or lsp.handlers[method]
        params = params or {}

        params.method = method
        code_actions.handler(method, params, handler, bufnr)
        formatting.handler(method, params, handler, bufnr)

        -- return long request id to (hopefully) prevent overlapping with actual client
        if params._null_ls_handled then
            return true, methods.internal._REQUEST_ID
        end

        -- call original handler to pass non-handled requests through to server
        return original_request(method, params, handler, bufnr)
    end

    -- null-ls can't (currently) cancel requests, so return true if id matches
    client.cancel_request = function(request_id)
        if request_id == methods.internal._REQUEST_ID then
            return true
        end
    end
end

return M
