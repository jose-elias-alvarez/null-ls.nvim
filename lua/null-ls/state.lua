local api = vim.api

local initial_state = {
    actions = {},
    cache = {},
    commands = {},
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

M.set_command = function(bufnr, base, resolved)
    state.commands[bufnr] = state.commands[bufnr] or {}
    state.commands[bufnr][base] = resolved
end

M.get_command = function(bufnr, base)
    return state.commands[bufnr] and state.commands[bufnr][base]
end

M.clear_commands = function(bufnr)
    state.commands[bufnr] = nil
end

return M
