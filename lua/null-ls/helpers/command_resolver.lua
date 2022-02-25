local log = require("null-ls.logger")
local s = require("null-ls.state")
local u = require("null-ls.utils")
local fmt = string.format

local M = {}

-- Search for a local install of an executable by searching relative to
-- startpath, then walking up directories until endpath is reached.
local function search_ancestors_for_command(startpath, endpath, executable_to_find)
    local resolved
    u.path.traverse_parents(startpath, function(dir)
        local command = u.path.join(dir, executable_to_find)
        if u.is_executable(command) then
            resolved = { command = command, cwd = dir }
            return true
        end
        if dir == endpath then
            return true
        end
    end)
    return resolved
end

M.generic = function(params, prefix)
    local resolved = s.get_resolved_command(params.bufnr, params.command)
    if resolved then
        if resolved.command then
            log:debug(fmt("Using cached value [%s] as the resolved command for [%s]", resolved.command, params.command))
        end
        return resolved.command
    end

    local executable_to_find = prefix and u.path.join(prefix, params.command) or params.command
    log:debug("attempting to find local executable " .. executable_to_find)

    resolved = search_ancestors_for_command(params.bufname, u.get_root(), executable_to_find)
    if resolved then
        log:trace(fmt("resolved dynamic command for [%s] with cwd=%s", executable_to_find, resolved.cwd))
    else
        log:debug(fmt("Unable to resolve command [%s], skipping further lookups", executable_to_find))
        resolved = { command = false }
    end

    s.set_resolved_command(params.bufnr, params.command, resolved)
    return resolved.command
end

M.from_node_modules = function(params)
    -- try the local one first by default but always fallback on the pre-defined command
    -- this needs to be done here to avoid constant lookups
    -- we're checking if the global is executable to avoid spawning an invalid command
    return M.generic(params, u.path.join("node_modules", ".bin")) or u.is_executable(params.command) and params.command
end

M.from_yarn_pnp = function(params)
    local cache_key = fmt("yarn:%s", params.command)
    local resolved = s.get_resolved_command(params.bufnr, cache_key)
    if resolved then
        if resolved.command then
            log:debug(fmt("Using cached value [%s] as the resolved command for [%s]", resolved.command, params.command))
        end
        return resolved.command
    end

    -- older yarn versions use `.pnp.js`, so look for both new and old names
    local root = u.get_root()
    local pnp_loader = search_ancestors_for_command(params.bufname, root, ".pnp.cjs")
        or search_ancestors_for_command(params.bufname, root, ".pnp.js")
    if pnp_loader then
        local yarn_bin = vim.fn.system(
            fmt("cd %s && yarn bin %s", vim.fn.shellescape(pnp_loader.cwd), vim.fn.shellescape(params.command))
        ):gsub("%s+", "")
        if vim.v.shell_error == 0 then
            log:trace(fmt("resolved dynamic command for [%s] to Yarn PnP with cwd=%s", params.command, pnp_loader.cwd))
            resolved = {
                command = { "node", "--require", pnp_loader.command, yarn_bin },
                cwd = pnp_loader.cwd,
            }
        end
    end

    resolved = resolved or { command = false }

    s.set_resolved_command(params.bufnr, cache_key, resolved)
    return resolved.command
end

return M
