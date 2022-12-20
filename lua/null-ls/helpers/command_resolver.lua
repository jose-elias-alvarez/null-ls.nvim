local cache = require("null-ls.helpers.cache")
local u = require("null-ls.utils")

local M = {}

--- search for a local executable and its parent directory from start_path to end_path
---@param start_path string
---@param end_path string
---@param executable string
---@return string|nil, string|nil
local function search_ancestors_for_executable(start_path, end_path, executable)
    local resolved_executable, resolved_dir
    for dir in vim.fs.parents(start_path) do
        local maybe_executable = u.path.join(dir, executable)
        if u.is_executable(maybe_executable) then
            resolved_executable = maybe_executable
            resolved_dir = dir
            break
        end
        -- stop at end_path
        if dir == end_path then
            break
        end
    end

    return resolved_executable, resolved_dir
end

--- creates a resolver that searches for a local executable and caches results by bufnr
---@param prefix string|nil
M.generic = function(prefix)
    ---@param params NullLsParams
    ---@return string|nil
    return cache.by_bufnr(function(params)
        local executable_to_find = prefix and u.path.join(prefix, params.command) or params.command
        if not executable_to_find then
            return
        end

        local resolved_executable = search_ancestors_for_executable(params.bufname, u.get_root(), executable_to_find)
        return resolved_executable
    end)
end

--- creates a resolver that searches for a local node_modules executable and falls back to a global executable
M.from_node_modules = function()
    local node_modules_resolver = M.generic(u.path.join("node_modules", ".bin"))
    return function(params)
        return node_modules_resolver(params) or params.command
    end
end

--- creates a resolver that searches for a local yarn pnp executable and falls back to a global executable
M.from_yarn_pnp = function()
    return cache.by_bufnr(function(params)
        local ok, yarn_command = pcall(function()
            local root = params.root
            if not root then
                error("unable to resolve root directory")
            end

            -- older yarn versions use `.pnp.js`, so look for both new and old names
            local pnp_executable, pnp_dir = search_ancestors_for_executable(params.bufname, root, ".pnp.cjs")
            if not (pnp_executable and pnp_dir) then
                pnp_executable, pnp_dir = search_ancestors_for_executable(params.bufname, root, ".pnp.js")
            end
            if not (pnp_executable and pnp_dir) then
                error("failed to find yarn executable")
            end

            local yarn_bin_cmd =
                string.format("cd %s && yarn bin %s", vim.fn.shellescape(pnp_dir), vim.fn.shellescape(params.command))
            local yarn_bin = vim.fn.system(yarn_bin_cmd):gsub("%s+", "")
            if vim.v.shell_error ~= 0 then
                error("failed to get yarn bin")
            end

            return { "node", "--require", pnp_executable, yarn_bin }
        end)

        return ok and yarn_command or params.command
    end)
end

return M
