local _initial_state = {client_id = nil, actions = {}, attached = {}}
local _state = _initial_state

local M = {}

local lsp = vim.lsp
local validate = vim.validate

local reset = function() _state = _initial_state end

M.get = function() return _state end
M.set =
    function(new_state) _state = vim.tbl_extend("force", _state, new_state) end
M.reset = reset

-- client
M.set_client_id = function(client_id) _state.client_id = client_id end

M.stop_client = function()
    lsp.stop_client(_state.client_id)
    reset()
end

-- actions
M.push_action =
    function(action) _state.actions[action.title] = action.action end

M.run_action = function(title)
    local action = _state.actions[title]
    validate({action = {action, "function"}})

    action()
end

M.clear_actions = function() _state.actions = {} end

-- diagnostics
M.attach = function(bufname)
    if bufname ~= "" then _state.attached[bufname] = true end
end

M.is_attached = function(bufname) return _state.attached[bufname] end

M.detach = function(bufname) _state.attached[bufname] = nil end

M.detach_all = function() _state.attached = {} end

return M
