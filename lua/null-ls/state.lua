local initial_state = {client_id = nil, actions = {}}
local state = initial_state

local M = {}

local lsp = vim.lsp
local validate = vim.validate

local reset = function() state = vim.deepcopy(initial_state) end

M.get = function() return state end
M.set =
    function(new_state) state = vim.tbl_extend("force", state, new_state) end
M.reset = reset

-- client
M.set_client_id = function(client_id) state.client_id = client_id end

M.stop_client = function()
    lsp.stop_client(state.client_id)
    reset()
end

-- actions
M.push_action = function(action) state.actions[action.title] = action.action end

M.run_action = function(title)
    local action = state.actions[title]
    validate({action = {action, "function"}})

    action()
end

M.clear_actions = function() state.actions = {} end

return M
