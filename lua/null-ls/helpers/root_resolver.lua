local log = require("null-ls.logger")
local u = require("null-ls.utils")
local fmt = string.format

local M = {}

M.root_markers = {
    python = {
        "pyproject.toml",
        "setup.cfg",
        "tox.ini",
        ".flake8",
    },
    node = {
        ".eslintrc*",
        "package.json",
        "tsconfig.json",
        "jsconfig.json",
        ".prettierrc*",
    },
}

M.from_python_markers = function(params)
    local cwd = u.root_pattern(M.root_markers.python)(params.bufname)
    log:trace(fmt("Using python markers: [%s]", M.root_markers.python))
    if cwd and cwd ~= "" then
        log:debug(fmt("Resolved python project path: [%s]", cwd))
    else
        log:debug("Unable to resolved python project path")
    end
    return cwd
end

M.from_node_markers = function(params)
    local cwd = u.root_pattern(M.root_markers.node)(params.bufname)
    log:trace(fmt("Using node markers: [%s]", M.root_markers.node))
    log:debug(fmt("Resolved node project path: [%s]", cwd or ""))
    return cwd
end

return M
