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
local validate = vim.validate

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
    lsp.buf_attach_client(bufnr, state.client_id)
    state.attached[vim.uri_from_bufnr(bufnr)] = bufnr
end

M.detach = function(uri) state.attached[uri] = nil end

-- actions
M.register_action =
    function(action) state.actions[action.title] = action.action end

M.run_action = function(title)
    local action = state.actions[title]
    validate({action = {action, "function"}})

    action()
end

M.clear_actions = function() state.actions = {} end

return M
