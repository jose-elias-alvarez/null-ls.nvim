local helpers = require("null-ls.helpers")
local c = require("null-ls.config")

local M = {}

M.register = c.register
M.is_registered = c.is_registered
M.register_name = c.register_name

M.methods = require("null-ls.methods").internal
M.builtins = require("null-ls.builtins")
M.null_ls_info = require("null-ls.info")

M.generator = helpers.generator_factory
M.formatter = helpers.formatter_factory

local should_setup = function()
    return not vim.g.null_ls_disable and not c.get()._setup
end

-- preferred method
M.config = function(user_config)
    if not should_setup() then
        return
    end

    c.setup(user_config or {})
    require("null-ls.rpc").setup()
    require("null-ls.lspconfig").setup()
    require("null-ls.handlers").setup()

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

return M
