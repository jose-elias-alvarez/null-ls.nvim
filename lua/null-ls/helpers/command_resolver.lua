local log = require("null-ls.logger")
local s = require("null-ls.state")
local u = require("null-ls.utils")
local fmt = string.format

local M = {}

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

    local root = u.get_root()

    resolved = {}

    u.path.traverse_parents(params.bufname, function(dir)
        local command = u.path.join(dir, executable_to_find)
        if u.is_executable(command) then
            log:trace(fmt("resolved dynamic command for [%s] with cwd=%s", executable_to_find, dir))
            resolved.command = command
            resolved.cwd = dir
            return true
        end

        -- use cwd as a stopping point to avoid scanning the entire file system
        if dir == root then
            return true
        end
    end)

    if not resolved.command then
        log:debug(fmt("Unable to resolve command [%s], skipping further lookups", executable_to_find))
    end

    s.set_resolved_command(params.bufnr, params.command, { command = resolved.command or false, cwd = resolved.cwd })
    return resolved.command
end

M.from_node_modules = function(params)
    -- try the local one first by default but always fallback on the pre-defined command
    -- this needs to be done here to avoid constant lookups
    -- we're checking if the global is executable to avoid spawning an invalid command
    return M.generic(params, u.path.join("node_modules", ".bin")) or u.is_executable(params.command) and params.command
end

return M
