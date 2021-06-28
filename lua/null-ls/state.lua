local c = require("null-ls.config")
local methods = require("null-ls.methods")
local loop = require("null-ls.loop")

local api = vim.api
local lsp = vim.lsp

local initial_state = {
    client_id = nil,
    client = nil,
    on_attach = nil,
    keep_alive_timer = nil,
    rtp = nil,
    actions = {},
    attached = {},
    cache = {},
}

local state = vim.deepcopy(initial_state)

local reset = function()
    state = vim.deepcopy(initial_state)
end

local M = {}

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

M.get_rtp = function()
    if not state.rtp then
        local me = debug.getinfo(1, "S").source:sub(2)
        state.rtp = vim.fn.fnamemodify(me, ":p:h:h:h")
        assert(state.rtp, "null-ls.nvim must be available on your rtp")
    end
    return state.rtp
end

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

M.attach = function(bufnr)
    local uri = vim.uri_from_bufnr(bufnr)
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

-- cache
M.set_cache = function(bufnr, cmd, content)
    if not api.nvim_buf_is_loaded(bufnr) then
        return
    end

    local uri = vim.uri_from_bufnr(bufnr)
    if not state.cache[uri] then
        state.cache[uri] = {}
    end

    state.cache[uri][vim.fn.fnamemodify(cmd, ":t")] = content
end

M.get_cache = function(bufnr, cmd)
    if not api.nvim_buf_is_loaded(bufnr) then
        return
    end

    local uri = vim.uri_from_bufnr(bufnr)
    return state.cache[uri] and state.cache[uri][vim.fn.fnamemodify(cmd, ":t")]
end

M.clear_cache = function(uri)
    if not state.cache[uri] then
        return
    end

    state.cache[uri] = nil
end

return M
