local api = vim.api

local initial_state = {
    actions = {},
    cache = {},
    commands = {},
    conditional_sources = {},
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

-- commands
M.set_resolved_command = function(bufnr, base, resolved)
    state.commands[bufnr] = state.commands[bufnr] or {}
    state.commands[bufnr][base] = resolved
end

M.get_resolved_command = function(bufnr, base)
    return state.commands[bufnr] and state.commands[bufnr][base]
end

M.clear_commands = function(bufnr)
    state.commands[bufnr] = nil
end

-- conditional sources
M.has_conditional_sources = function()
    return #state.conditional_sources > 0
end

M.push_conditional_source = function(source)
    table.insert(state.conditional_sources, source)
end

M.register_conditional_sources = function()
    vim.tbl_map(function(source)
        source.try_register()
    end, state.conditional_sources)

    state.conditional_sources = {}
end

return M
