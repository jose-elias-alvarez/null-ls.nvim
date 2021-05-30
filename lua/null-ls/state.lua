local c = require("null-ls.config")
local methods = require("null-ls.methods")
local loop = require("null-ls.loop")

local initial_state = {
    client_id = nil,
    client = nil,
    on_attach = nil,
    keep_alive_timer = nil,
    actions = {},
    attached = {},
}
local state = vim.deepcopy(initial_state)

local M = {}

local lsp = vim.lsp

local reset = function()
    state = vim.deepcopy(initial_state)
end

M.get = function()
    return state
end
M.set = function(new_state)
    state = vim.tbl_extend("force", state, new_state)
end
M.reset = reset

-- client
local notify_client = function(method, params)
    if not state.client then
        return
    end
    state.client.notify(method, params)
end
M.notify_client = notify_client

M.initialize = function(client)
    state.client = client

    local interval = c.get().keep_alive_interval
    state.keep_alive_timer = loop.timer(0, interval, true, function()
        notify_client(methods.internal._NOTIFICATION, { timeout = interval })
    end)
end

M.shutdown_client = function(timeout)
    if not state.client then
        return
    end
    if state.keep_alive_timer then
        state.keep_alive_timer.stop(true)
    end

    lsp.stop_client(state.client_id)
    vim.wait(timeout or 5000, function()
        return state.client == nil or state.client.is_stopped() == true
    end, 10)

    reset()
end

M.attach = function(bufnr, uri)
    uri = uri or vim.uri_from_bufnr(bufnr)
    if state.attached[uri] then
        return
    end

    lsp.buf_attach_client(bufnr, state.client_id)
    state.attached[uri] = bufnr
end

M.detach = function(uri)
    state.attached[uri] = nil
end

-- actions
M.register_action = function(action)
    state.actions[action.title] = action.action
end

M.run_action = function(title)
    local action = state.actions[title]
    if not action then
        return
    end

    action()
end

M.clear_actions = function()
    state.actions = {}
end

return M
