local next_key = 0

local M = {}

M.cache = {}

--- creates a function that caches the output of a callback, indexed by bufnr
---@param cb function
---@return fun(params: NullLsParams): any
M.by_bufnr = function(cb)
    -- assign next available key, since we just want to avoid collisions
    local key = next_key
    M.cache[key] = {}
    next_key = next_key + 1

    return function(params)
        local bufnr = params.bufnr
        -- if we haven't cached a value yet, get it from cb
        if M.cache[key][bufnr] == nil then
            -- make sure we always store a value so we know we've already called cb
            M.cache[key][bufnr] = cb(params) or false
        end

        return M.cache[key][bufnr]
    end
end

M._reset = function()
    M.cache = {}
end

return M
