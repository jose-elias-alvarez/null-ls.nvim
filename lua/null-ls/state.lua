local initial_state = {
    client_id = nil,
    on_attach = nil,
    initialized = nil,
    actions = {},
    attached = {}
}
local state = vim.deepcopy(initial_state)

local M = {}

local lsp = vim.lsp

local reset = function() state = vim.deepcopy(initial_state) end

M.get = function() return state end
M.set =
    function(new_state) state = vim.tbl_extend("force", state, new_state) end
M.reset = reset

-- client
M.stop_client = function()
    lsp.stop_client(state.client_id)
    reset()
end

M.attach = function(bufnr)
    local uri = vim.uri_from_bufnr(bufnr)
    if state.attached[uri] then return end

    lsp.buf_attach_client(bufnr, state.client_id)
    state.attached[uri] = bufnr
end

M.detach = function(uri) state.attached[uri] = nil end

-- actions
M.register_action =
    function(action) state.actions[action.title] = action.action end

M.run_action = function(title)
    local action = state.actions[title]
    if not action then return end

    action()
end

M.clear_actions = function() state.actions = {} end

return M
