local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local builtins = require("null-ls.builtins")
local lspconfig = require("null-ls.lspconfig")
local handlers = require("null-ls.handlers")
local rpc = require("null-ls.rpc")
local u = require("null-ls.utils")
local c = require("null-ls.config")

local M = {}

M.register = c.register
M.is_registered = c.is_registered
M.register_name = c.register_name

M.methods = methods.internal
M.generator = helpers.generator_factory
M.formatter = helpers.formatter_factory
M.builtins = builtins

local should_setup = function()
    return not vim.g.null_ls_disable and not c.get()._setup
end

-- preferred method
M.config = function(user_config)
    if not should_setup() then
        return
    end

    c.setup(user_config or {})
    rpc.setup()
    lspconfig.setup()
    handlers.setup()

    vim.cmd("command! NullLsInfo lua require('null-ls').null_ls_info()")
end

-- here for backwards compatibility, but deprecated
M.setup = function(user_config)
    if not should_setup() then
        return
    end

    user_config = user_config or {}
    M.config(user_config)
    require("lspconfig")["null-ls"].setup({ on_attach = user_config.on_attach })
end

M.null_ls_info = function()
    local ft = vim.bo.filetype
    local registered_methods = c.get()._methods

    local active = {}
    for method, source in pairs(registered_methods) do
        for name, filetypes in pairs(source) do
            if u.filetype_matches(filetypes, ft) then
                active[method] = active[method] or {}
                table.insert(active[method], name)
            end
        end
    end

    -- TODO: make this nice
    print("active sources for filetype " .. ft)
    print(vim.inspect(active))
end

return M
